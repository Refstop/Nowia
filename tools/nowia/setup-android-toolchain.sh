#!/usr/bin/env bash
# Reproduce the Android/JDK setup recorded on 2026-10-13; Linux x86_64 only.
# Retain the managed proxy and CA trust. Installing SDK packages accepts licenses.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
task_tools="${NOWIA_TOOLCHAIN_ROOT:-$(dirname -- "$root")/toolchains}"
task_downloads="${NOWIA_SETUP_EVIDENCE_DIR:-$root/build/nowia-setup-evidence/android}"
[[ "$task_tools" = /* && "$task_downloads" = /* ]] || {
  echo 'Toolchain and evidence directories must be absolute.' >&2; exit 2;
}
[[ "$(uname -s)" = Linux && "$(uname -m)" = x86_64 ]] || {
  echo 'This setup requires Linux x86_64.' >&2; exit 2;
}
for target in "$task_tools/jdk-21" "$task_tools/android-sdk" "$task_downloads"; do
  [[ ! -e "$target" && ! -L "$target" ]] || {
    printf 'Refusing to overwrite existing path: %s\n' "$target" >&2; exit 2;
  }
done
mkdir -p -- "$task_tools" "$(dirname -- "$task_downloads")"
mkdir -- "$task_downloads"
exec > >(tee "$task_downloads/setup.log") 2>&1
trap 'setup_exit=$?; printf "%s\n" "$setup_exit" > "$task_downloads/exit-code.txt"' EXIT
mkdir -p -- "$task_tools/jdk-21" "$task_tools/android-sdk/cmdline-tools/latest"

curl --fail --location --retry 2 \
  'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_x64_linux_hotspot_21.0.12.1_1.tar.gz' \
  -o "$task_downloads/jdk21.tar.gz"
python3 - "$task_downloads/jdk21.tar.gz" <<'PY'
import hashlib, pathlib, sys
# Matches the official release .sha256.txt downloaded in the original setup.
actual = hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest()
if actual != 'ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94':
    raise SystemExit('Temurin archive SHA-256 mismatch')
PY
tar --no-same-owner -xzf "$task_downloads/jdk21.tar.gz" -C "$task_tools/jdk-21" --strip-components=1

curl --fail --location --retry 2 \
  'https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip' \
  -o "$task_downloads/cmdline-tools.zip"
python3 - "$task_downloads/cmdline-tools.zip" "$task_tools/android-sdk/cmdline-tools/latest" <<'PY'
import hashlib, os, pathlib, stat, sys, zipfile
src, dest = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
data = src.read_bytes()
# SHA-1 is from Google's repository metadata; SHA-256 records the fetched bytes.
if (hashlib.sha1(data).hexdigest() != 'e025545c62a8e64c7559119566a569fb1dec5f60'
    or hashlib.sha256(data).hexdigest() != '0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8'):
    raise SystemExit('Android command-line tools archive checksum mismatch')
with zipfile.ZipFile(src) as archive:
    for entry in archive.infolist():
        path = pathlib.PurePosixPath(entry.filename)
        mode = entry.external_attr >> 16
        if path.is_absolute() or '..' in path.parts or stat.S_ISLNK(mode):
            raise SystemExit('Unsafe Android archive entry')
        out = dest / path.relative_to('cmdline-tools')
        if entry.is_dir():
            out.mkdir(parents=True, exist_ok=True)
        else:
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_bytes(archive.read(entry))
            os.chmod(out, mode & 0o777 or 0o644)
PY

export JAVA_HOME="$task_tools/jdk-21"
export ANDROID_HOME="$task_tools/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
if [[ -f /etc/ssl/certs/java/cacerts ]]; then
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts"
fi
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
# cmdline-tools 23 delegates to Android CLI and consumes inherited system proxies.
# --licenses is no longer needed. Installation writes licenses/android-sdk-license.
android --no-metrics --sdk="$ANDROID_HOME" sdk install \
  platform-tools platforms/android-36 platforms/android-35 build-tools/36.0.0 ndk/28.2.13676358 cmake/3.22.1
android --no-metrics --sdk="$ANDROID_HOME" sdk list
android --no-metrics --version
java -version
javac -version
