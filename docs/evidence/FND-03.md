# FND-03 unchanged Butterfly build attempt

> Historical handoff evidence. For the 2026-10-13 managed Cloud resumption, see [FND-03-resume.md](FND-03-resume.md) and [current status](../status.md). The observations below describe the previous attempt only.

**Status: BLOCKED / NOT PASSED. No APK was produced.** The official source and exact Flutter/Dart runtimes were verified locally. The app compiler was not reached; these outcomes do not establish a Butterfly source defect or a successful build.

Audit date: 2026-10-12 UTC / 2026-10-13 KST. This report covers the isolated local attempt only, not any later Nowia CI run.

## Source baseline and integrity

| Item | Locally observed result |
|---|---|
| Official repository | https://github.com/LinwoodDev/Butterfly |
| Clone command | `git clone --branch v2.6.0 --depth 1 https://github.com/LinwoodDev/Butterfly.git /workspace/scratch/26e6ed352677/butterfly-baseline` |
| Clone exit | 0 |
| Tag | `v2.6.0` |
| HEAD | `1e4c86b91f4d64361a73598bda0acc587f9381b0` |
| Checkout | `/workspace/scratch/26e6ed352677/butterfly-baseline` |
| Before and after `git status --porcelain=v1` | Empty |
| Before and after `git diff --exit-code` | Exit 0 |
| App lock SHA-256 | `fbc231cdef6548052a57a9809a070e6682ce6fe156e39984a40ea552ef6e490a` |
| API lock SHA-256 | `e5fa6063dc3c9d0781d5630775eb068f6cd3a6498f694c4f62f7af3b2ab27e24` |
| APK inventory after attempts | Empty |

No Butterfly application code, manifest, tracked generated code or dependency lock was changed. Before/after checks are captured in `source-before.json` and `source-after.json`. The initial clone returned a detached checkout of the exact commit; this is a shallow source reproduction checkout, not a claim that full upstream history was imported into Nowia.

## Toolchain: runtime verified versus missing

| Component | Observed status |
|---|---|
| Flutter source | Official tag `3.47.5` cloned successfully; exact commit `6a19cca56475dbfba1478ee68d7bd0c2ef891da1` verified |
| Flutter runtime | `flutter --version` exit 0; Flutter **3.47.5**, framework revision `6a19cca564` |
| Engine | Revision `af7e796e161ae0bb1ff0758c71a7105418bd9ded`; runtime engine hash `ab598368592da0064197e2bc15c7f5b0a2c6bb1f` |
| Dart runtime | Direct `dart --version` exit 0: **3.13.4 stable**, linux_x64 |
| DevTools runtime reported by Flutter | **2.60.0** |
| Existing Java | OpenJDK **17.0.20** runtime, exit 0; `javac` not on PATH |
| JDK 21 | Not installed. Official Adoptium asset API request returned HTTP 403 once; no alternate route attempted |
| Google Android SDK / adb | Not installed or configured; direct Flutter environment preflight reports `No Android SDK found` |
| Rust | Not on PATH; upstream-required **1.98.1** was not installed/executed |
| Gradle / AGP / Kotlin compilation | Not reached |

Flutter `[user-branch]` channel label is from the detached exact-tag checkout. It is not a version substitution. The Flutter SDK, pub cache and any build caches were confined to task-specific scratch paths. `CI=true` and `FLUTTER_SUPPRESS_ANALYTICS=true` were used.

Flutter bootstrap downloaded the 227 MB Linux x64 Dart SDK and resolved the Flutter tool's own package dependencies. Its bootstrap output `Changed 101 dependencies` belongs to the Flutter tool, **not** Butterfly app dependency resolution. The later Flutter artifact label `Android SDK` refers to Flutter Android engine artifacts; it does not establish installation of Google Android platform/build tools or accepted SDK licenses.

Initial host observation: approximately 9.2 GiB available memory, 30 GiB available disk, no swap. These are measured resources, not sufficient evidence of build readiness.

## Actual commands and outcomes

All Flutter commands used the executable `/workspace/scratch/26e6ed352677/toolchains/flutter/bin/flutter`. Build commands ran from `/workspace/scratch/26e6ed352677/butterfly-baseline/app`.

| Run | Command | Outcome | Interpretation |
|---|---|---|---|
| SDK verification | `flutter --version` | Exit 0 | Exact runtime verified |
| First unchanged build | `flutter build apk --debug --flavor production` | Exit **1** | Flutter Gradle-wrapper archive extraction failed before application dependencies or compilation |
| Environment-adjusted retry | Same command with `TAR_OPTIONS=--no-same-owner` | **300-second diagnostic timeout**; process returned 0 after SIGTERM | No build success; application dependency resolution was still active |
| Environment preflight only | `flutter build apk --debug --flavor production --no-pub` with same tar option | Exit **1** | `No Android SDK found. Try setting the ANDROID_HOME environment variable.` |

First attempt: 2026-10-12T16:13:01.887130+00:00 to 2026-10-12T16:13:21.521359+00:00.
Retry: 2026-10-12T16:13:54.616724+00:00 to 2026-10-12T16:18:54.625171+00:00.
Preflight: 2026-10-12T16:19:13.720012+00:00 to 2026-10-12T16:19:13.985399+00:00.

The first failure was `tar` exit 2 while unpacking Flutter's own Gradle-wrapper archive: the archive's UID 397546 / GID 5000 ownership could not be applied in this container (`Invalid argument`). The retry's task-local `TAR_OPTIONS=--no-same-owner` avoided ownership mutation and passed that extraction. No source patch or permission escalation was used.

The retry successfully downloaded framework/Android engine cache artifacts, then remained at `Resolving dependencies...` until the harness limit. Cache growth was observed; no package-specific error was emitted. This is an **incomplete dependency-resolution observation**, not proof that dependencies are broken. The process handled SIGTERM with exit 0; `harness_timeout=true` overrides that exit code and must never be reported as a pass.

The final `--no-pub` command deliberately skipped unresolved application dependencies to expose the next environment requirement. It is an environment diagnostic, not a valid end-to-end FND-03 build attempt or acceptance result. It confirmed Google Android SDK absence immediately.

## Other network and SDK observations

- `curl --head --location --max-time 20 https://pub.dev`: exit 0, HTTP 200.
- Android repository XML fetched via the official Google URL with HTTP 200; source data and extracted metadata are retained.
- Metadata lists Android platform 36, NDK `28.2.13676358`, command-line tools and other packages with `android-sdk-license` references.
- No Android SDK license acceptance was performed, no license file fabricated, and no SDK packages were installed. This agent was instructed not to accept new legal terms without explicit authorization.
- The Adoptium API returned HTTP 403. The response was not enough to identify whether the origin or environment policy caused it; the report makes no stronger claim.

## Gates that remain open

| Gate | Status / next evidence required |
|---|---|
| Complete app dependency resolution | Pending: successful `flutter pub get` or the normal build's dependency stage, with preserved lock hashes and no silent upgrades |
| Complete matching build environment | Blocked locally: authorized/pre-provisioned Android SDK/licenses, JDK 21 and Rust 1.98.1 required; exact runtime versions must be captured |
| Unmodified debug APK | Not produced: normal `flutter build apk --debug --flavor production` must exit 0 without a timeout and yield an actual APK |
| APK provenance | Pending: file path/size/SHA-256, source commit, toolchain versions, build log, source/lock diff, package/minSdk/signature inspection |
| Device installation | Not run: no attached/authorized Galaxy Tab S7/Android13 device was available to this worker |
| Physical S Pen / palm behavior | Not run; emulator, synthetic input or metadata cannot substitute |
| Save → process termination → relaunch restore | Not run; requires actual app/device evidence |

A prepared CI workflow or an upstream successful release run does not close these local/Nowia build gates. Any subsequent CI result should be reported as a separate environment with its own provenance.

## Evidence files

`docs/evidence/local-build/` contains complete logs, command arrays, timestamps and exit outcomes. Key files:

- `source-before.json`, `source-after.json`, `apk-inventory.json`
- `flutter-clone.log`, `flutter-clone.json`, `flutter-source.json`
- `flutter-version.log`, `flutter-version.json`, `dart-version.json`
- `flutter-build-apk.log`, `flutter-build-apk.json`
- `flutter-build-apk-no-owner.log`, `flutter-build-apk-no-owner.json`
- `flutter-build-apk-preflight.log`, `flutter-build-apk-preflight.json`
- `host-environment.json`, `pub-connectivity.json`, `temurin-fetch-status.json`
- `android-repository.xml`, `android-package-metadata.json`, `result-summary.json`

`docs/evidence/local-build-index.json` records evidence file sizes and SHA-256 digests after all attempts finished. Upstream source/license declarations remain in `audit-upstream.md`; declarations must not be presented as local execution results.
