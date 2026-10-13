#!/usr/bin/env python3
"""Fail-closed upstream quality checks and opt-in CI failure probes.

Every subprocess records its command, exit status and complete output. A probe
returns the real failing status, so a dispatched probe must make its CI job red.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


class GateFailure(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code if code > 0 else 128 - code


def interrupted(signum, _frame):
    raise GateFailure(128 + signum, f"Interrupted by signal {signum}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--probe", choices=("none", "integrity", "compile"), default="none")
    parser.add_argument("--evidence", type=Path, help="New directory; existing evidence is never overwritten")
    args = parser.parse_args()
    if args.evidence:
        evidence = args.evidence.resolve()
        evidence.mkdir(parents=True, exist_ok=False)
    else:
        base = ROOT / "build/nowia-evidence"
        base.mkdir(parents=True, exist_ok=True)
        evidence = Path(tempfile.mkdtemp(prefix="quality-", dir=base))
    pins = json.loads((ROOT / "tools/nowia/baseline.json").read_text())
    stages = []
    result = {"started_utc": utc(), "probe": args.probe,
              "upstream_commit": pins["upstream_commit"], "stages": stages,
              "quality": "NOT_RUN", "source_after": "NOT_RUN",
              "expected_failure_observed": False}

    def save():
        (evidence / "result.json").write_text(json.dumps(result, indent=2) + "\n")

    def run(name, command, *, cwd=ROOT, timeout=120, check=True):
        command = [str(part) for part in command]
        record = {"stage": name, "command": command, "cwd": str(cwd),
                  "started_utc": utc(), "timeout_seconds": timeout,
                  "timed_out": False, "exit_code": None, "log": f"{name}.log"}
        stages.append(record)
        save()
        print(f"START {name}: {command!r}", flush=True)
        process = None
        with (evidence / record["log"]).open("w") as output:
            try:
                process = subprocess.Popen(command, cwd=cwd, stdout=output,
                                           stderr=subprocess.STDOUT, start_new_session=True)
                record["exit_code"] = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                record.update(timed_out=True, exit_code=124)
            except GateFailure as exc:
                record.update(exit_code=exc.code, interrupted=str(exc))
            except OSError as exc:
                output.write(str(exc) + "\n")
                record["exit_code"] = 127
            finally:
                if process is not None and process.poll() is None:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
                record["ended_utc"] = utc()
                save()
        with (evidence / record["log"]).open() as output:
            shutil.copyfileobj(output, sys.stdout)
        print(f"END {name}: exit={record['exit_code']}", flush=True)
        if record.get("interrupted") or (check and record["exit_code"]):
            raise GateFailure(record["exit_code"], f"{name} failed")
        return record

    def verify(phase):
        return run(f"source-{phase}", [sys.executable, ROOT / "tools/nowia/verify_baseline.py"], check=False)

    def failure_probe():
        with tempfile.TemporaryDirectory(prefix="nowia-failure-probe-") as temporary:
            temporary = Path(temporary)
            if args.probe == "integrity":
                checkout = temporary / "source"
                run("probe-worktree-add", ["git", "worktree", "add", "--detach", checkout, "HEAD"])
                try:
                    target = checkout / "app/pubspec.yaml"
                    with target.open("a") as output:
                        output.write("\n# NOWIA_INTENTIONAL_INTEGRITY_FAILURE\n")
                    failed = run("probe-integrity", [sys.executable, checkout / "tools/nowia/verify_baseline.py"],
                                 cwd=checkout, check=False)
                    marker = "NOWIA_INTENTIONAL_INTEGRITY_FAILURE"
                finally:
                    run("probe-worktree-remove", ["git", "worktree", "remove", "--force", checkout])
            else:
                fixture = temporary / "compile_error.dart"
                fixture.write_bytes((ROOT / "tools/nowia/tests/compile-error.dart.fixture").read_bytes())
                failed = run("probe-compile", ["dart", "compile", "exe", fixture,
                                              "-o", temporary / "must-not-exist"], check=False)
                marker = "NOWIA_INTENTIONAL_COMPILE_FAILURE"
            log = (evidence / failed["log"]).read_text()
            result["expected_failure_observed"] = bool(failed["exit_code"] and marker in log
                                                       and not failed["timed_out"])
            if not result["expected_failure_observed"]:
                raise GateFailure(1, "Probe did not reach its intended failure; inspect the raw stage log")
            raise GateFailure(failed["exit_code"], f"Expected {args.probe} failure propagated to CI")

    signal.signal(signal.SIGINT, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    exit_code = 1
    save()
    try:
        run("commit", ["git", "rev-parse", "HEAD"])
        if verify("before")["exit_code"]:
            raise GateFailure(1, "Upstream integrity check failed")
        if args.probe != "integrity":
            run("flutter-version", ["flutter", "--version", "--machine"])
            flutter = json.loads((evidence / "flutter-version.log").read_text())
            for field, pin in (("frameworkVersion", "flutter_version"), ("frameworkRevision", "flutter_revision")):
                if flutter.get(field) != pins[pin]:
                    raise GateFailure(1, f"TOOLCHAIN_MISMATCH {field}: {flutter.get(field)} != {pins[pin]}")
            run("dart-version", ["dart", "--version"])
        if args.probe != "none":
            failure_probe()
        result["quality"] = "IN_PROGRESS"
        run("app-pub-get", ["flutter", "pub", "get", "--enforce-lockfile"], cwd=ROOT / "app", timeout=1800)
        run("api-pub-get", ["dart", "pub", "get", "--enforce-lockfile"], cwd=ROOT / "api", timeout=1800)
        if verify("after-pub")["exit_code"]:
            raise GateFailure(1, "Dependency resolution changed upstream source or lockfiles")
        run("app-analyze", ["flutter", "analyze", "--no-pub", "--fatal-infos"], cwd=ROOT / "app", timeout=600)
        run("api-analyze", ["dart", "analyze", "--fatal-infos"], cwd=ROOT / "api", timeout=600)
        run("api-test", ["dart", "test", "--reporter", "expanded", "--concurrency=2"], cwd=ROOT / "api", timeout=900)
        run("app-test", ["flutter", "test", "--no-pub", "--reporter", "expanded", "--concurrency=2"],
            cwd=ROOT / "app", timeout=1800)
        result["quality"] = "PASS"
        exit_code = 0
    except GateFailure as exc:
        exit_code = exc.code
        result["error"] = str(exc)
    except Exception as exc:
        result["error"] = f"{type(exc).__name__}: {exc}"
    finally:
        if result["quality"] == "IN_PROGRESS":
            result["quality"] = "FAIL"
        final = verify("after")
        result["source_after"] = "PASS" if not final["exit_code"] else "FAIL"
        if final["exit_code"] and not exit_code:
            exit_code = 1
            result["error"] = "Final source/lockfile verification failed"
        result.update(ended_utc=utc(), exit_code=exit_code)
        save()
        (evidence / "exit-code.txt").write_text(f"{exit_code}\n")
        print(f"RESULT: exit={exit_code}; evidence={evidence}", flush=True)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
