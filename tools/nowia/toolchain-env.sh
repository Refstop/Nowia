#!/usr/bin/env bash
# Source this file from setup, quality, and build entry points.
nowia_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
nowia_toolchain="${NOWIA_TOOLCHAIN_ROOT:-$(dirname -- "$nowia_root")/toolchains}"
[[ "$nowia_toolchain" = /* ]] || { echo 'NOWIA_TOOLCHAIN_ROOT must be absolute.' >&2; return 2; }
export NOWIA_TOOLCHAIN_ROOT="$nowia_toolchain"
export JAVA_HOME="$nowia_toolchain/jdk-21"
export ANDROID_HOME="$nowia_toolchain/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export CARGO_HOME="$nowia_toolchain/cargo"
export RUSTUP_HOME="$nowia_toolchain/rustup"
export PUB_CACHE="$nowia_toolchain/pub-cache"
export GRADLE_USER_HOME="$nowia_toolchain/gradle-cache"
export PATH="$JAVA_HOME/bin:$nowia_toolchain/flutter/bin:$CARGO_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
case " ${TAR_OPTIONS:-} " in
  *' --no-same-owner '*) ;;
  *) export TAR_OPTIONS="${TAR_OPTIONS:+$TAR_OPTIONS }--no-same-owner" ;;
esac

# Keep the managed proxy and CA trust. Java does not use shell proxy variables.
nowia_java_network_options="$(python3 - <<'PY'
import os
from pathlib import Path
from urllib.parse import urlsplit
options = []
trust = Path(os.environ.get('NOWIA_JAVA_TRUST_STORE', '/etc/ssl/certs/java/cacerts'))
if trust.is_file():
    options.append(f'-Djavax.net.ssl.trustStore={trust}')
for scheme in ('http', 'https'):
    value = os.environ.get(f'{scheme.upper()}_PROXY') or os.environ.get(f'{scheme}_proxy')
    if value:
        proxy = urlsplit(value)
        if not proxy.hostname or proxy.username or proxy.password:
            raise SystemExit('A supported managed Java proxy configuration is required.')
        options.extend((f'-D{scheme}.proxyHost={proxy.hostname}',
                        f'-D{scheme}.proxyPort={proxy.port or (443 if proxy.scheme == "https" else 80)}'))
print(' '.join(options))
PY
)" || return $?
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }$nowia_java_network_options"
