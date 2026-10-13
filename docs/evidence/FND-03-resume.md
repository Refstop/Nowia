# FND-03 재개 — 원본 APK 빌드 성공

2026-10-13 KST. 판정: **VERIFIED (현재 managed Cloud 환경, 원격 미병합)**. 원본 debug APK를 생성하고 재현용 wrapper까지 검증했다. 별도 새 환경 재현이나 Galaxy Tab 실기기 시험을 완료했다는 뜻은 아니다.

## 출처와 복원

- 업로드 `nowia_fnd_01_03_handoff.zip` SHA-256: `6be686cc75f5e8d10cab2a2c5f15e6232f8044ee58791fb2a2cfed3ddffc3f18`.
- [인계 무결성](resume-build/handoff-integrity.json): 등록된 65개 파일 bytes/SHA-256 일치.
- 공식 Butterfly tag `v2.6.0` → `1e4c86b91f4d64361a73598bda0acc587f9381b0`를 새로 clone하고 확인했다.
- 기존 Nowia main의 README를 보존해 snapshot import, import tree `a6969e6a0e2e0703d7a86aeba11957111278bb54` 확인 후 인계 patch 적용.
- 복원 HEAD `d1feecc5beecc21bb30901135f6d9eca04b9c94c`, 복원 tree `51dbbcd09c11409f792d46b3c7d6f0307f773492`, branch `task/fnd-03-resume`.
- 실행 당시 root의 wrapper/문서는 수정 상태였다. [실행 파일 hash](resume-build/tooling.sha256)와 wrapper의 status-before/after 로그로 구분한다. 앱/API bytes는 원본이다.

## 실제 실행

| 실행 | 결과 | 증거 |
|---|---|---|
| 원본/도구 복원 | Flutter3.47.5, Dart3.13.4, JDK21, SDK/NDK, Rust 설치 및 실행 성공 | `resume-build/source`, `flutter`, `android`, `rust` |
| 최초 `flutter pub get --enforce-lockfile` | exit 0, 약 24초, lockfile 그대로 | [pub 로그](resume-build/pub/resolve.log) |
| 최초 `flutter build apk --debug --flavor production --no-pub` | exit 0, 16:28:58–16:36:29 KST, 약 451초 | [명령·시간·exit](resume-build/first-apk/result.json), [전체 로그](resume-build/first-apk/build.log) |
| `NOWIA_EVIDENCE_DIR=/workspace/build-resume-evidence/wrapper bash tools/nowia/build-cloud.sh` | exit 0, 16:36:49–16:37:07 KST, 전체 약 18초 | [wrapper 결과](resume-build/wrapper/result.json) |
| wrapper의 lock-enforced pub → source → APK → 서명/manifest → source/lock | 26개 단계 모두 exit 0, timeout 없음 | [전체 실행 로그](resume-build/wrapper/build.log), 각 단계 `.json/.log` |

`--no-pub`는 성공한 lock-enforced 의존성 해석 다음에만 사용했다. 이전 인계의 unresolved `--no-pub` 진단과 다르다. 첫 빌드와 wrapper 실행 모두 실제 Gradle assembleProductionDebug가 완료됐다. 두 번째는 같은 환경의 cache를 사용했으므로 새 환경 재현으로 세지 않는다.

## APK 검증

- 원 출력: `/workspace/Nowia/app/build/app/outputs/flutter-apk/app-production-debug.apk`.
- 전달 사본: `/workspace/Nowia/build/artifacts/butterfly-v2.6.0-production-debug.apk`.
- 크기: **219,409,984 bytes**. SHA-256: **`da100dbcde47a4b8d03c3ef1e0cbce869146a5ca2beaf929babf2bedf1263c5b`**.
- [manifest](resume-build/wrapper/apk-manifest.log): `dev.linwood.butterfly`, `2.6.0+199`, label Butterfly, debuggable, compile/target/min `36/36/24`, arm64-v8a/armeabi-v7a/x86_64.
- [서명 검사](resume-build/wrapper/apk-signature.log): `apksigner verify --verbose --print-certs` exit 0, v2=true, 서명자 1명, Android Debug.
- 인증서 SHA-256: `f8653120416ed6cd01f0af3b1e2241078690a56ed45246c2aadd02bc925ea9ce`.
- APK 수정 시각은 wrapper 시작 이후다. 오래된 파일을 성공 산출물로 재사용하지 않았다. 첫 빌드와 재실행 hash도 일치한다.
- [기계 판정](resume-build/apk-verification.json): 위 package/version/SDK/ABI/label 항목을 기대값과 비교했다.

## 원본과 도구

빌드 전후 `verify_baseline.py` PASS: app `ff163eaaab6fbf214b87f76c1edb133cc9edd4d6`, api `3d0f3e16e0f55ad4c593568dae8262f3ffbad55d`. 추적 source·생성 파일·manifest·lockfile 변경 없음.

- app lock SHA-256: `fbc231cdef6548052a57a9809a070e6682ce6fe156e39984a40ea552ef6e490a`.
- api lock SHA-256: `e5fa6063dc3c9d0781d5630775eb068f6cd3a6498f694c4f62f7af3b2ab27e24`.
- Flutter `3.47.5` / full SHA `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, Dart `3.13.4`, Temurin/javac `21.0.12.1`, app Rust `1.98.1`.
- SDK API36 rev2, 플러그인용 API35 rev2, build-tools36.0.0, NDK28.2.13676358, CMake3.22.1. [실제 SDK 목록](resume-build/wrapper/sdk-packages.log).
- OneNote 의존성 자체 Rust pin은 `1.98.0`; hook이 제한된 환경에서 `/home/agent/.rustup`을 사용함을 실행 경로로 확인했다. [native 증거](resume-build/native/onenote-rust-version.json). 앱 Rust pin을 바꾸지 않았다.
- Gradle9.7.1/AGP9.4.0/Kotlin2.4.20 원본 설정을 유지했다. Java proxy/CA와 tar 옵션만 환경에 반영했다.

원본 Greek ICU plural 및 향후 Kotlin migration 경고는 빌드 로그에 남겼으며 해당 source를 수정하지 않았다. Doctor의 Chrome/Linux 부족 및 별도 네트워크 probe 경고는 Android APK 성공 판정을 대체하지 않는다. Android toolchain 항목은 실제 PASS다.

## 변경 및 후속

변경 범위는 setup/build wrapper와 문서·증거다. wrapper는 실행별 로그, 명령·exit·timeout, 실패 후 최종 원본 검사, 새 APK 여부, checksum·서명·manifest를 기록한다. 스크립트 문법 및 missing-Flutter 실패 처리(exit127, 최종 source/lock 기록)도 확인했다. setup 스크립트의 새 환경 전체 재다운로드 실행은 아직 미검증이다.

FND-03 현재 환경 검증은 완료했다. 원격 push/PR/merge와 CI는 이번 작업에서 NOT_RUN. FND-04 새 task 재현 전까지 G0는 NOT_ACCEPTED. APP-01은 WAITING_DEVICE, G1도 NOT_ACCEPTED. 기존 공식 앱·노트를 삭제하거나 실기기 검증을 수행하지 않았다. 이전 실패 기록은 [FND-03.md](FND-03.md)에 보존했다.
