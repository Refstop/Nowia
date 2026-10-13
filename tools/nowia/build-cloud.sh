#!/usr/bin/env bash
# Use the prepared task-local toolchain. Build hooks may bootstrap their caches.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$root/tools/nowia/toolchain-env.sh"
exec bash "$root/tools/nowia/build-baseline.sh" "$@"
