#!/usr/bin/env bash
# A new container, home and toolchain for every committed-source reproduction.
# Uses the managed local daemon, proxy defaults and read-only CA mounts.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
image="nowia-fnd04:ubuntu26.04"
mode="${1:-run}"
output="${2:-$(dirname -- "$root")/fnd04-repro}"
ca_bundle="${NOWIA_CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}"
java_trust="${NOWIA_JAVA_TRUST_STORE:-/etc/ssl/certs/java/cacerts}"

docker_local() {
  env -u DOCKER_HOST -u DOCKER_CONTEXT -u DOCKER_TLS \
    -u DOCKER_TLS_VERIFY -u DOCKER_CERT_PATH \
    docker --host=unix:///var/run/docker.sock "$@"
}
usage() {
  echo 'Usage: bash tools/nowia/reproduce-container.sh prepare|start|wait|run ABSOLUTE_OUTPUT_DIRECTORY' >&2
  echo 'prepare builds only the base image; start launches detached; wait propagates its result; run does both.' >&2
  exit 2
}
[[ "$mode" =~ ^(prepare|start|wait|run)$ && "$output" = /* && $# -le 2 ]] || usage
docker_local info --format '{{.ServerVersion}}' >/dev/null

wait_for_run() {
  [[ -f "$output/container-id.txt" ]] || { echo 'Missing container identity.' >&2; exit 2; }
  local container_id result log_pid
  container_id="$(cat "$output/container-id.txt")"
  [[ "$container_id" =~ ^[0-9a-f]{64}$ ]] || { echo 'Invalid container identity.' >&2; exit 2; }
  docker_local logs --follow "$container_id" >"$output/container.log" 2>&1 &
  log_pid=$!
  if ! result="$(docker_local wait "$container_id")"; then
    kill "$log_pid" 2>/dev/null || true
    wait "$log_pid" || true
    echo 'Could not obtain the container result.' >&2
    return 125
  fi
  wait "$log_pid" || true
  [[ "$result" =~ ^[0-9]+$ ]] || { echo 'Invalid container exit code.' >&2; return 125; }
  printf '%s\n' "$result" >"$output/container-exit-code.txt"
  docker_local inspect --format '{{json .State}}' "$container_id" >"$output/container-state.json"
  printf 'Container exit=%s; evidence=%s\n' "$result" "$output"
  return "$result"
}
if [[ "$mode" == wait ]]; then
  wait_for_run
  exit $?
fi

[[ -f "$ca_bundle" && -f "$java_trust" ]] || {
  echo 'A combined CA bundle and Java trust store are required.' >&2; exit 2;
}
[[ ! -e "$output" && ! -L "$output" ]] || { echo 'Evidence directory must be new.' >&2; exit 2; }
mkdir -p -- "$(dirname -- "$output")"
mkdir -- "$output"
docker_local version --format '{{json .}}' >"$output/docker-version.json"
docker_local build --secret "id=combined_ca,src=$ca_bundle" \
  --tag "$image" "$root/tools/nowia/container" 2>&1 | tee "$output/image-build.log"
docker_local image inspect --format '{{json .Id}}' "$image" >"$output/image-id.json"
sha256sum "$root/tools/nowia/container/Dockerfile" >"$output/dockerfile.sha256"
if [[ "$mode" == prepare ]]; then
  echo "Base image prepared; evidence=$output"
  exit 0
fi

# Run only immutable committed input. Generated outputs and host caches are not
# cloned. --no-local copies Git objects instead of sharing source object files.
[[ -z "$(git -C "$root" status --porcelain=v1 --untracked-files=normal)" ]] || {
  echo 'Commit all intended source changes before reproduction; worktree is dirty.' >&2; exit 2;
}
for script in setup-cloud.sh quality-gate.sh build-cloud.sh; do
  git -C "$root" cat-file -e "HEAD:tools/nowia/$script"
done
source_commit="$(git -C "$root" rev-parse HEAD)"
printf '%s\n' "$source_commit" >"$output/source-commit.txt"
git -C "$root" status --porcelain=v1 >"$output/source-status-before.txt"

cat >"$output/entrypoint.sh" <<'INNER'
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
INNER

# The Docker client injects its managed, container-reachable proxy defaults.
# Never replace them with outer-container proxy hostnames or host networking.
container_id="$(docker_local run --detach \
  --mount "type=bind,src=$root,dst=/source,readonly" \
  --mount "type=bind,src=$output,dst=/evidence" \
  --mount "type=bind,src=$ca_bundle,dst=/etc/ssl/certs/ca-certificates.crt,readonly" \
  --mount "type=bind,src=$java_trust,dst=/etc/ssl/certs/java/cacerts,readonly" \
  --env "NOWIA_SOURCE_COMMIT=$source_commit" \
  --env SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  --env CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
  --env GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
  --env REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
  --env CI=true --env FLUTTER_SUPPRESS_ANALYTICS=true \
  "$image" bash /evidence/entrypoint.sh)"
printf '%s\n' "$container_id" >"$output/container-id.txt"
docker_local inspect --format '{{json .Mounts}}' "$container_id" >"$output/container-mounts.json"
docker_local inspect --format '{{json .HostConfig.NetworkMode}}' "$container_id" >"$output/container-network-mode.json"
printf 'Started container %s; evidence=%s\n' "$container_id" "$output"
if [[ "$mode" == run ]]; then
  wait_for_run
fi
