#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /evidence/run.log) 2>&1
trap 'result=$?; printf "%s\n" "$result" >/evidence/exit-code.txt; date -u +%FT%TZ >/evidence/ended-utc.txt' EXIT
date -u +%FT%TZ >/evidence/started-utc.txt
cat /etc/os-release >/evidence/os-release.txt
dpkg-query -W -f='${Package}\t${Version}\n' >/evidence/host-packages.tsv
[[ ! -e /work/Nowia && ! -e /work/toolchains && ! -e /root/.pub-cache && ! -e /root/.gradle && ! -e /root/.rustup ]]
printf 'Fresh container filesystem, toolchain directories and home caches verified.\n' >/evidence/isolation.txt
git -c safe.directory=/source clone --no-local /source /work/Nowia
cd /work/Nowia
git checkout --detach "$NOWIA_SOURCE_COMMIT"
test "$(git rev-parse HEAD)" = "$NOWIA_SOURCE_COMMIT"
git status --porcelain=v1 >/evidence/clone-status.txt
[[ ! -s /evidence/clone-status.txt ]]
python3 tools/nowia/verify_baseline.py

stage() {
  local name="$1" result
  shift
  printf 'START %s\n' "$name"
  printf '%q ' "$@" >"/evidence/$name-command.txt"
  printf '\n' >>"/evidence/$name-command.txt"
  set +e
  "$@" > >(tee "/evidence/$name.log") 2>&1
  result=$?
  set -e
  printf '%s\n' "$result" >"/evidence/$name-exit-code.txt"
  printf 'END %s exit=%s\n' "$name" "$result"
  return "$result"
}
export NOWIA_TOOLCHAIN_ROOT=/work/toolchains
export NOWIA_SETUP_EVIDENCE_DIR=/evidence/setup
stage setup bash tools/nowia/setup-cloud.sh
stage quality bash tools/nowia/quality-gate.sh --evidence /evidence/quality
export NOWIA_EVIDENCE_DIR=/evidence/build
stage build bash tools/nowia/build-cloud.sh
mkdir /evidence/artifacts
cp app/build/app/outputs/flutter-apk/app-production-debug.apk /evidence/artifacts/butterfly-v2.6.0-production-debug.apk
sha256sum /evidence/artifacts/*.apk >/evidence/artifacts/apk.sha256
git status --porcelain=v1 >/evidence/source-status-after.txt
python3 tools/nowia/verify_baseline.py
