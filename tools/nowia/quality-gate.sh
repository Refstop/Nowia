#!/usr/bin/env bash
# Analyze/test the pinned upstream without rewriting generated code or lockfiles.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$root/tools/nowia/toolchain-env.sh"
exec python3 "$root/tools/nowia/quality-gate.py" "$@"
