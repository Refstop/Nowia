#!/usr/bin/env python3
"""Verify unchanged app/api trees and tracked bytes before/after baseline builds."""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
PINS = json.loads((ROOT / "tools/nowia/baseline.json").read_text())

def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()

for path, expected in PINS["source_trees"].items():
    actual = git("rev-parse", f"HEAD:{path}")
    if actual != expected:
        raise SystemExit(f"FAIL {path}: expected {expected}, got {actual}")
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--", path], cwd=ROOT, check=True)
    extra = git("ls-files", "--others", "--exclude-standard", "--", path)
    if extra:
        raise SystemExit(f"FAIL untracked source in {path}: {extra}")
    print(f"PASS {path} unchanged tree {actual}")
print(f"UPSTREAM {PINS['upstream_commit']}")
print(f"NOWIA {git('rev-parse', 'HEAD')}")
