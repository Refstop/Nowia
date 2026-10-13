#!/usr/bin/env bash
# Linux x86_64 setup for a new, empty toolchain directory. No source changes.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$root/tools/nowia/toolchain-env.sh"
evidence="${NOWIA_SETUP_EVIDENCE_DIR:-$root/build/nowia-setup-evidence/cloud}"
[[ "$(uname -s)" = Linux && "$(uname -m)" = x86_64 ]] || {
  echo 'This setup requires Linux x86_64.' >&2; exit 2;
}
[[ "$evidence" = /* ]] || { echo 'Setup evidence path must be absolute.' >&2; exit 2; }
if [[ -e "$NOWIA_TOOLCHAIN_ROOT" ]] && [[ -n "$(ls -A -- "$NOWIA_TOOLCHAIN_ROOT")" ]]; then
  echo 'Setup requires an empty toolchain directory; use build-cloud.sh for an existing installation.' >&2
  exit 2
fi
mkdir -p -- "$(dirname -- "$evidence")"
mkdir -- "$evidence"
mkdir -p -- "$NOWIA_TOOLCHAIN_ROOT"
exec > >(tee "$evidence/setup.log") 2>&1
trap 'result=$?; printf "%s\n" "$result" > "$evidence/exit-code.txt"; date -u +%FT%TZ > "$evidence/ended-utc.txt"' EXIT
date -u +%FT%TZ > "$evidence/started-utc.txt"
git -C "$root" rev-parse HEAD > "$evidence/source-commit.txt"
sha256sum "$root/tools/nowia/setup-cloud.sh" "$root/tools/nowia/setup-android-toolchain.sh" > "$evidence/setup-scripts.sha256"

NOWIA_SETUP_EVIDENCE_DIR="$evidence/android" bash "$root/tools/nowia/setup-android-toolchain.sh"

readarray -t flutter_pins < <(python3 - "$root/tools/nowia/baseline.json" <<'PY'
import json, sys
pins = json.load(open(sys.argv[1]))
print(pins['flutter_version'])
print(pins['flutter_revision'])
print(pins['rust_version'])
PY
)
git clone --depth 1 --branch "${flutter_pins[0]}" https://github.com/flutter/flutter.git "$NOWIA_TOOLCHAIN_ROOT/flutter"
test "$(git -C "$NOWIA_TOOLCHAIN_ROOT/flutter" rev-parse HEAD)" = "${flutter_pins[1]}"
flutter --version
flutter --version --machine > "$evidence/flutter-version.json"

# Versioned installer archive; matches bytes observed during FND-03.
curl --fail --location --retry 2 --connect-timeout 20 --max-time 180 \
  https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-unknown-linux-gnu/rustup-init \
  -o "$NOWIA_TOOLCHAIN_ROOT/rustup-init"
printf '%s  %s\n' dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71 \
  "$NOWIA_TOOLCHAIN_ROOT/rustup-init" | sha256sum --check
chmod +x "$NOWIA_TOOLCHAIN_ROOT/rustup-init"
"$NOWIA_TOOLCHAIN_ROOT/rustup-init" -y --no-modify-path --profile minimal --default-toolchain "${flutter_pins[2]}"
rustup --version
rustc --version
flutter precache --android
flutter doctor -v
python3 "$root/tools/nowia/verify_baseline.py"
