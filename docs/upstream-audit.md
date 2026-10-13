# Butterfly v2.6.0 upstream read-only audit

Audit date: 2026-10-12 UTC / 2026-10-13 KST. Official GitHub API and exact-ref source files were read through the GitHub connector. No upstream or Nowia mutation was performed by this audit.

## Scope and evidence levels

- **Observed source facts**: exact tag resolution, manifest/lockfile/build/CI/license source, complete Git tree.
- **Observed remote CI metadata**: a release run and APK job reported success at the same commit.
- **Not executed here**: clone/checkout, dependency installation, compiler, APK build, APK binary checksum verification, APK install, S Pen/device tests.
- CI metadata is supporting upstream evidence; it does **not** satisfy FND-03's requirement for our own unchanged debug APK build.
- Full job log retrieval was attempted once and failed with tool transport error `Transport closed`. No compiler exit code or runtime SDK patch version was obtained from that log.

## Immutable upstream identity

| Item | Observed value |
|---|---|
| Repository | https://github.com/LinwoodDev/Butterfly |
| Baseline tag | v2.6.0 |
| Annotated tag object | 68cb06f1aeb6562977ed0a796eed2fba12cb7448 |
| Peeled commit | **1e4c86b91f4d64361a73598bda0acc587f9381b0** |
| Tag date | 2026-09-28T08:29:10Z |
| Tag signature | GitHub reports unsigned, verified=false |
| Release | https://github.com/LinwoodDev/Butterfly/releases/tag/v2.6.0 |
| Release metadata | published 2026-09-28T08:29:29Z, prerelease=false |
| App manifest | 2.6.0+199 |
| API manifest | 2.6.0 |
| Submodules | Complete recursive tree has no gitlink entries and no .gitmodules |
| Generated files | 44 tracked *.g.dart / *.freezed.dart files |
| Upstream structure | app/ Flutter app; api/ Dart models; tools/ Dart tools; docs/ documentation |

Tag API:
- https://api.github.com/repos/LinwoodDev/Butterfly/git/ref/tags/v2.6.0
- https://api.github.com/repos/LinwoodDev/Butterfly/git/tags/68cb06f1aeb6562977ed0a796eed2fba12cb7448
- https://api.github.com/repos/LinwoodDev/Butterfly/git/trees/v2.6.0?recursive=1

Freeze the peeled commit, not the movable develop/main/stable branch/tag. v2.6.0 is the examined baseline; this audit does not claim it is the latest release.

## License inventory (source-confirmed; not complete dependency legal clearance)

| Scope | Observed license | Exact-ref source |
|---|---|---|
| App/default project code | AGPL-3.0 per README; root license text is GNU AGPL v3 | README.md, LICENSE |
| api/ files | Apache-2.0 exception explicitly stated in README | api/LICENSE, README.md |
| app/images/ and docs/ contents | CC-BY-SA-4.0 explicitly stated in README | BRANDING_LICENSE, README.md |
| Comfortaa font | SIL OFL 1.1; reserved font name Comfortaa | app/fonts/Comfortaa-LICENSE.txt |
| Noto Sans Arabic font | SIL OFL 1.1 | app/fonts/NotoSansArabic-LICENSE.txt |
| Roboto font | Apache 2.0 | app/fonts/Roboto-LICENSE.txt |

Observed text and scope must be retained in provenance. Do not label all assets Apache or all of the repository AGPL without the documented exceptions. The app's own code does not become Apache merely by importing api/. Full transitive dependency license inventory, new branding design/rights review, and final distribution/source-offer design remain **unverified**. No independent license grant for original Butterfly names/trademarks was established here.

Exact source base URL for every repository-relative source in this report:
https://github.com/LinwoodDev/Butterfly/blob/1e4c86b91f4d64361a73598bda0acc587f9381b0/

## Build toolchain: declared versus executed

| Item | Source-confirmed declaration | Runtime status |
|---|---|---|
| Flutter | 3.47.5 in app/pubspec.yaml; CI flutter-version-file points there | Not run here |
| Flutter upstream ref | 3.47.5 -> 6a19cca56475dbfba1478ee68d7bd0c2ef891da1 | Ref resolved via official GitHub API |
| Dart | >=3.13.0 <4.0.0 in app/api manifests and locks | Exact installed patch version requires dart --version; not measured |
| JDK used by APK CI | Temurin 21 in .github/workflows/build.yml | Exact JDK build not measured |
| Java and Kotlin bytecode | 17 in app/android/app/build.gradle.kts | Not compiled here |
| Gradle wrapper | 9.7.1 | Not downloaded/executed here |
| Wrapper distribution checksum | acd53f1edaf02f1a8ff99879f8a34b302661a057d9b063ae9e35b552f804d20a | Configured upstream; ZIP not independently checked |
| Android Gradle Plugin | 9.4.0 | Not executed here |
| Kotlin Gradle Plugin | 2.4.20 | Not executed here |
| compileSdk / targetSdk | Delegated to Flutter, official 3.47.5 source default **36 / 36** | Installed SDK/merged manifest not checked |
| minSdk | Delegated to Flutter, official 3.47.5 source default **24** | Final dependency/merged manifest compatibility not checked |
| NDK | Delegated to Flutter, official 3.47.5 source default **28.2.13676358** | Not installed here |
| Rust | app/rust-toolchain.toml pins **1.98.1**, APK CI installs Rust | Not run here |
| CI runner declaration | ubuntu-26.04 in APK workflow source | Runner log unavailable |
| Gradle JVM memory settings | -Xmx8G; MaxMetaspaceSize=4G; ReservedCodeCacheSize=512m | These are maxima, not measured resource use |
| AGP compatibility switches | android.newDsl=false; android.builtInKotlin=false | Preserve upstream values until proven necessary |

Primary toolchain sources:
- app/pubspec.yaml
- api/pubspec.yaml
- app/pubspec.lock
- api/pubspec.lock
- app/android/settings.gradle.kts
- app/android/app/build.gradle.kts
- app/android/gradle/wrapper/gradle-wrapper.properties
- app/android/gradle.properties
- app/rust-toolchain.toml
- .github/workflows/build.yml
- https://github.com/flutter/flutter/blob/3.47.5/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt
- https://api.github.com/repos/flutter/flutter/git/ref/tags/3.47.5

Important: JDK **21 for the build process** and Java/Kotlin **17 bytecode targets** are distinct and both source-confirmed. Do not change CI to JDK 17 based only on sourceCompatibility=17.

## Dependency locks

Source copies were written from fetched UTF-8 content, then each of 21 fetched files was byte-verified against its returned Git blob SHA. The audit's local source files are under upstream_evidence/. This is evidence retrieval, not a full checkout.

| File | Git blob SHA | SHA-256 of fetched exact bytes |
|---|---|---|
| app/pubspec.lock | 2131472cfe3d4d85fcee6a8cb26748385304927b | fbc231cdef6548052a57a9809a070e6682ce6fe156e39984a40ea552ef6e490a |
| api/pubspec.lock | 48d0681af9105141b9b1ebba55f379cc4f2f146d | e5fa6063dc3c9d0781d5630775eb068f6cd3a6498f694c4f62f7af3b2ab27e24 |

App lock lists 13 Git packages; every ref and resolved-ref is a full SHA and matches. api/ lock includes dart_leap and lw_file_system_api at the same SHAs. butterfly_api is a relative path dependency ../api.

| Git package | Repository/path | Locked resolved-ref |
|---|---|---|
| dart_leap | LinwoodDev/dart_pkgs packages/dart_leap | b7787191b0705ff0a22149409b1b360468d9e06d |
| keybinder | LinwoodDev/dart_pkgs packages/keybinder | 81eed1f96a53956b10f3ccfe4bc573bc17da5979 |
| lw_file_system | LinwoodDev/dart_pkgs packages/lw_file_system | 3382c23ca02c5c8362432919400edf6f4af5b678 |
| lw_file_system_api | LinwoodDev/dart_pkgs packages/lw_file_system_api | 37594211585889e35e65dad382d4fdcf29ac69a0 |
| lw_sysapi | LinwoodDev/dart_pkgs packages/lw_sysapi | 4504590d871958c48a93969461193691ea88cb18 |
| material_leap | LinwoodDev/dart_pkgs packages/material_leap | 2195d9d509f5ba2c5c823491d93cac4d6136b597 |
| networker | LinwoodDev/dart_pkgs packages/networker/networker | f7ba7bc32a37ffb5e8b5f63a3b1fbbb32e567c28 |
| networker_crypto | LinwoodDev/dart_pkgs packages/networker/networker_crypto | da60928e30f783a68e2daa48911f76b67c730c09 |
| networker_socket | LinwoodDev/dart_pkgs packages/networker/networker_socket | da60928e30f783a68e2daa48911f76b67c730c09 |
| onenote_parser | LinwoodDev/dart_pkgs packages/onenote_parser | 78d98f1eb5a40c4f0f351cdafeabc2eee3b56504 |
| phosphor_flutter | CodeDoctorDE/phosphor-flutter root | f7479596c67239e755ab1fe3bade84895bfd6222 |
| settings_leap | LinwoodDev/dart_pkgs packages/settings_leap | 855133902c6893903ff4ea36a99ef8279ded5121 |
| swamp_api | LinwoodDev/Swamp api | 957467dc575763883dccb8a7d0585eeaeb0f853f |

These dependency repositories and package archives were not themselves downloaded or individually license-audited. Availability and resolution must be proved by pub get in the target environment. Avoid pub upgrade during baseline reproduction.

## Code generation and first unchanged build

Observed upstream APK job order:
1. Checkout.
2. Setup Temurin JDK 21.
3. Setup Rust from app/rust-toolchain.toml.
4. Flutter action from app/pubspec.yaml.
5. In app/: flutter pub get.
6. Optional upstream signing secrets import.
7. flutter build apk -v --release --flavor production for stable release.
8. Also build legacy packaging and split-per-ABI variants.

The APK build workflow does not explicitly regenerate build_runner files first. Tracked generated Dart files are already present. Flutter localization generation is enabled by flutter.generate: true. For the first source baseline, preserve tracked generated files and lockfiles.

Observed .github/workflows/dart.yml quality job:
- Matrix app/api/tools.
- flutter pub get.
- app only: flutter gen-l10n then dart format lib/src/generated.
- dart format --output=none --set-exit-if-changed lib.
- flutter analyze --fatal-infos.
- app/api: dart run build_runner build --delete-conflicting-outputs then dart format .
- git diff --exit-code.
- app: flutter test; api: dart test.

Suggested FND-03 debug reproduction command derived from the upstream flavor configuration, **not executed or validated by this audit**:
```sh
cd app
flutter pub get
flutter build apk --debug --flavor production
```

Expected conventional output, **not observed artifact**:
`app/build/app/outputs/flutter-apk/app-production-debug.apk`.

Preserve the unmodified source/lockfile diff and report any generated changes after build. Separate generation verification from changing source to solve a dependency issue.

## Signing, app identity, and install implications

- production and development flavors both use dev.linwood.butterfly (empty suffix).
- nightly flavor uses dev.linwood.butterfly.nightly.
- Upstream release configuration uses release keystore if android/key.properties exists; otherwise falls back to debug signing.
- Upstream signed release APK and a local debug-signed APK sharing dev.linwood.butterfly are not assumed update-compatible. Do not uninstall/erase an existing installation or its notes to make the test pass.
- Preserve unchanged baseline first; distinct Nowia app ID and rebranding are a separate approved modification after the baseline. User has named the product Nowia; no Nowia app ID is established by this audit.
- A production-flavor debug build is functional validation, not representative pen performance measurement.

## Remote upstream evidence

Same peeled commit:
- Release run: https://github.com/LinwoodDev/Butterfly/actions/runs/36397668094
- APK job: https://github.com/LinwoodDev/Butterfly/actions/runs/36397668094/job/108847817834
- Run event: release; conclusion: success.
- APK job conclusion: success, 2026-09-28T08:43:11Z to 09:00:15Z.
- Production, production legacy, production split-per-ABI, production legacy split-per-ABI, arm64 size-analysis steps all reported success.
- At least one other same-commit push Flutter build failed and two were cancelled; do not claim every run passed.
- Job log download failed with Transport closed, so exact run-level tool versions and compiler output remain uninspected.

Release asset metadata (server-declared SHA-256, **binary not downloaded/hash-checked here**):

| Asset | Size bytes | Declared SHA-256 |
|---|---:|---|
| linwood-butterfly-android-arm64.apk | 47078334 | 786ef744b1b23e2746fd6813ce96b1d0aa0737894b984dfddfed9bb871c9dbd1 |
| linwood-butterfly-android.apk | 126066884 | 5ccd60b3f74a1f53296a76021ae36e94d37c8e8b1cbc70c914b00ebc7c95dddb |

These official artifacts can be comparison inputs, but cannot be reported as an APK built by Nowia.

## Completion gates to preserve

- FND-02 only complete after Nowia holds the intended history/baseline and exact source difference is inspected; this audit alone does not create the thin fork.
- FND-03 only complete after actual unchanged **debug APK** generation with command, exit status, tool versions, source SHA, lock hashes, APK path/checksum and log.
- Galaxy Tab S7 / S Pen / Android 13 remains a separate device gate: install, pen/palm input, save, process termination, relaunch/restore must be executed and evidenced.
- ADB/UI metadata or synthetic input cannot establish real S Pen pressure, palm rejection, or physical input latency.
- Cloud/CI connection status and prior Cloud errors are outside this audit and must be verified separately.

