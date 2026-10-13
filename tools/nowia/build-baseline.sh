#!/usr/bin/env bash
# Requires a prepared toolchain; does not install packages or accept licenses.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
export TAR_OPTIONS="${TAR_OPTIONS:+$TAR_OPTIONS }--no-same-owner"
if [[ -n "${NOWIA_EVIDENCE_DIR:-}" ]]; then
  [[ "$NOWIA_EVIDENCE_DIR" = /* ]] || { echo 'NOWIA_EVIDENCE_DIR must be absolute.' >&2; exit 2; }
  evidence="$NOWIA_EVIDENCE_DIR"
  mkdir -p -- "$(dirname -- "$evidence")"
  mkdir -- "$evidence" # Reject existing directories and stale evidence.
else
  mkdir -p build/nowia-evidence
  evidence="$(mktemp -d "$root/build/nowia-evidence/$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
fi
exec > >(tee "$evidence/build.log") 2>&1
printf 'EVIDENCE: %s\n' "$evidence"
python3 - "$root" "$evidence" <<'PY'
import datetime
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time

root, evidence = map(Path, sys.argv[1:])
pins = json.loads((root / 'tools/nowia/baseline.json').read_text())
started_ns = time.time_ns()
stages = []

def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()

def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')

class BuildFailure(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code

def interrupted(signum, _frame):
    raise BuildFailure(128 + signum, f'Interrupted by signal {signum}')

signal.signal(signal.SIGINT, interrupted)
signal.signal(signal.SIGTERM, interrupted)

def run(name, command, *, cwd=root, timeout=120, check=True):
    command = [str(part) for part in command]
    record = {'stage': name, 'command': command, 'cwd': str(cwd), 'started_utc': utc(),
              'timeout_seconds': timeout, 'timed_out': False, 'exit_code': None, 'log': f'{name}.log'}
    stages.append(record)
    save(evidence / f'{name}.json', record)
    print(f'START {name}: {command!r}', flush=True)
    process = None
    with (evidence / record['log']).open('w') as output:
        try:
            process = subprocess.Popen(command, cwd=cwd, stdout=output,
                                       stderr=subprocess.STDOUT, start_new_session=True)
            record['exit_code'] = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            record.update(timed_out=True, exit_code=124)
        except BuildFailure as exc:
            record.update(exit_code=exc.code, interrupted=str(exc))
        except OSError as exc:
            output.write(str(exc) + '\n')
            record['exit_code'] = 127
        finally:
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            record['ended_utc'] = utc()
            save(evidence / f'{name}.json', record)
    # The stage log can be tailed while the command runs.
    with (evidence / record['log']).open() as output:
        shutil.copyfileobj(output, sys.stdout)
    print(f'END {name}: exit={record["exit_code"]} timeout={record["timed_out"]}', flush=True)
    if record.get('interrupted') or (check and record['exit_code']):
        raise BuildFailure(record['exit_code'], f'{name} failed')
    return record

def snapshot(phase):
    commands = {'source': ['python3', 'tools/nowia/verify_baseline.py'],
                'commit': ['git', 'rev-parse', 'HEAD'],
                'status': ['git', 'status', '--porcelain=v1'],
                'lockfiles': ['sha256sum', 'app/pubspec.lock', 'api/pubspec.lock']}
    results = [run(f'{name}-{phase}', command, check=False) for name, command in commands.items()]
    return next((item['exit_code'] for item in results if item['exit_code']), 0)

def versions(phase):
    commands = {'flutter': ['flutter', '--version', '--machine'], 'dart': ['dart', '--version'],
                'java': ['java', '-version'], 'javac': ['javac', '-version'], 'rust': ['rustc', '--version']}
    for name, command in commands.items():
        run(f'{name}-{phase}', command, cwd=root / 'app', check=phase == 'before')

sdk = Path(os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT') or '/nonexistent')
def sdk_tool(name):
    if found := shutil.which(name):
        return found
    paths = list(sdk.glob(f'build-tools/*/{name}')) + [sdk / 'cmdline-tools/latest/bin' / name]
    paths = [path for path in paths if path.is_file() and os.access(path, os.X_OK)]
    return str(sorted(paths)[-1]) if paths else None

result = {'started_utc': utc(), 'started_ns': started_ns, 'upstream_commit': pins['upstream_commit'],
          'evidence_directory': str(evidence), 'apk_build': 'NOT_RUN',
          'apk_signature': 'NOT_RUN', 'apk_manifest': 'NOT_RUN',
          'environment': {key: os.environ.get(key) for key in
                          ['JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'TAR_OPTIONS']}}
save(evidence / 'result.json', result)
exit_code = 1
try:
    if snapshot('before'):
        raise BuildFailure(1, 'Source or lockfile snapshot failed')
    versions('before')
    flutter = json.loads((evidence / 'flutter-before.log').read_text())
    for field, expected in [('frameworkVersion', pins['flutter_version']),
                            ('frameworkRevision', pins['flutter_revision'])]:
        if flutter.get(field) != expected:
            raise BuildFailure(1, f'TOOLCHAIN_MISMATCH {field}: {flutter.get(field)} != {expected}')
    for name, pattern in [('java', r'version "21(?:[.\"]|$)'),
                          ('javac', r'^javac 21(?:[.]|$)'), ('rust', r'^rustc 1\.98\.1 ')]:
        if not re.search(pattern, (evidence / f'{name}-before.log').read_text(), re.MULTILINE):
            raise BuildFailure(1, f'TOOLCHAIN_MISMATCH {name}')
    # Records the Java executable Flutter selects; optional desktop/device failures are diagnostic.
    run('flutter-doctor', ['flutter', 'doctor', '-v'], check=False)
    if manager := sdk_tool('sdkmanager'):
        run('sdk-packages', [manager, '--list_installed'], check=False)
    # --no-pub follows successful lock-enforced resolution, not an unresolved preflight.
    run('pub-get', ['flutter', 'pub', 'get', '--enforce-lockfile'], cwd=root / 'app', timeout=1800)
    run('source-after-pub', ['python3', 'tools/nowia/verify_baseline.py'])
    result['apk_build'] = 'IN_PROGRESS'
    run('build-apk', ['flutter', 'build', 'apk', '--debug', '--flavor', 'production', '--no-pub'],
        cwd=root / 'app', timeout=3600)
    apk = root / 'app/build/app/outputs/flutter-apk/app-production-debug.apk'
    if not apk.is_file() or not apk.stat().st_size:
        raise BuildFailure(1, 'Build returned success without a nonempty APK')
    if apk.stat().st_mtime_ns < started_ns:
        raise BuildFailure(1, 'APK predates this run; stale artifact rejected')
    result['apk_build'] = 'PASS'
    run('apk-sha256', ['sha256sum', apk])
    result['apk'] = {'path': str(apk), 'bytes': apk.stat().st_size,
                     'sha256': (evidence / 'apk-sha256.log').read_text().split()[0]}
    if signer := sdk_tool('apksigner'):
        result['apk_signature'] = 'IN_PROGRESS'
        run('apk-signature', [signer, 'verify', '--verbose', '--print-certs', apk])
        result['apk_signature'] = 'PASS'
    if aapt := sdk_tool('aapt'):
        result['apk_manifest'] = 'IN_PROGRESS'
        run('apk-manifest', [aapt, 'dump', 'badging', apk])
        result['apk_manifest'] = 'CAPTURED'
    elif analyzer := sdk_tool('apkanalyzer'):
        result['apk_manifest'] = 'IN_PROGRESS'
        run('apk-manifest', [analyzer, 'manifest', 'print', apk])
        result['apk_manifest'] = 'CAPTURED'
    exit_code = 0
except BuildFailure as exc:
    exit_code = exc.code
    result['error'] = str(exc)
except Exception as exc:
    result['error'] = f'{type(exc).__name__}: {exc}'
finally:
    # Final evidence is mandatory even after a failed setup, resolution or build.
    for field in ('apk_build', 'apk_signature', 'apk_manifest'):
        if result[field] == 'IN_PROGRESS':
            result[field] = 'FAIL'
    final_integrity = snapshot('after')
    result['source_after'] = 'PASS' if final_integrity == 0 else 'FAIL'
    if final_integrity and exit_code == 0:
        exit_code = final_integrity
        result['error'] = 'Final source or lockfile integrity verification failed'
    versions('after')
    result.update(ended_utc=utc(), exit_code=exit_code, stages=stages)
    save(evidence / 'result.json', result)
    (evidence / 'exit-code.txt').write_text(f'{exit_code}\n')
    print(f'RESULT: exit={exit_code}; evidence={evidence}', flush=True)
sys.exit(exit_code)
PY
