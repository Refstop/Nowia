Android/JDK setup completed 2026-10-13 UTC. This is setup evidence, not APK build success.

Ready environment:
JAVA_HOME=/workspace/toolchains/jdk-21
ANDROID_HOME=/workspace/toolchains/android-sdk
ANDROID_SDK_ROOT=/workspace/toolchains/android-sdk
JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts
PATH prepend: $JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
Inherited HTTP(S)_PROXY retained. No proxy bypass or TLS verification changes.

Inventory:
Temurin OpenJDK and javac 21.0.12.1+1-LTS (official SHA256 checked)
cmdline-tools source.properties 23.0 (manually extracted official archive)
Android CLI 1.0.16500706 (downloaded by official cmdline-tools wrapper)
platform-tools 37.0.1 (ADB 1.0.41 / 37.0.1-15733141)
platforms/android-36 revision 2 / API36 / extension17 / base SDK
build-tools 36.0.0 (aapt 0.2-13193326, apksigner 0.9)
NDK 28.2.13676358 / r28c (clang 19.0.1)

All java, javac, aapt, apksigner, adb, NDK clang and Android CLI list smoke checks exit0.
No device connection/install tests were performed.

Build-tools36.0.0 is the actual default of AGP9.4.0, verified from official
gradle-9.4.0.jar CommonExtensionImpl -> builder-9.4.0.jar ToolsRevisionUtils.
See *.javap and agp/builder.request.json. No guessed version override was applied.

SDK licenses:
Initial sdkmanager --licenses exit0 warns the option is no longer needed.
Actual sdkmanager install exit0 wrote licenses/android-sdk-license automatically.
SDK install used JAVA_HOME and JAVA_TOOL_OPTIONS above, and inherited proxy config.
The current sdkmanager wrapper explicitly warns proxy flags are unused; Android CLI
uses system proxy configuration. It fetched the official Google artifacts successfully.
The first wrapper invocation displayed optional CLI metrics notice; following commands
use --no-metrics. No android init / agent skill installation was performed.

Evidence references:
reproduce-setup.sh: executable reproduction recipe, no second installation performed.
*.request.json: curl commands, exit codes, elapsed seconds and download output.
jdk21-extract.json: official and observed SHA256, tar command and exit.
downloaded-sha256.json: fetched archive/artifact hashes.
sdk-selected-repository-artifacts.json: official metadata URLs, SHA1 and sizes.
sdk-install.command.json / sdk-install.result.json / sdk-install.log: actual setup.
installed-source-properties.json / sdk-installed.log: exact installed versions.
The CLI list reports cmdline-tools as unknown because this package was extracted
manually; its source.properties confirms 23.0 and official archive checksum matched.

The reproduction script pins JDK and commandline-tools downloads. SDK package names
platform-tools and platforms/android-36 select the latest revision at execution time;
this run's exact URLs/checksums and versions above are retained for comparison.
