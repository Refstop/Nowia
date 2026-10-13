# FND-03 — 수정 없는 Android 빌드 기준선

기록: 2026-10-13 KST. **현재 환경과 기존 개발 캐시를 가져오지 않은 새 컨테이너에서 원본 production/debug APK 빌드·서명·소스 보존 검증 PASS.** 원격 CI와 별도 APK artifact 다운로드·hash 대조도 완료했다. [ADR-006](adr/ADR-006-ci-reproduction.md)에 따라 G0를 통과했다. Cloud 설정 publish·별도 Codex task는 NOT_RUN, 실기기 검증은 대기 중이다.

## 결과와 실행

- Butterfly v2.6.0: `1e4c86b91f4d64361a73598bda0acc587f9381b0`
- 인계 복원 branch: `task/fnd-03-resume`
- 실행 당시 Nowia HEAD: `d1feecc5beecc21bb30901135f6d9eca04b9c94c`. 빌드 도구 수정은 당시 미커밋 상태였으며 [tooling.sha256](evidence/resume-build/tooling.sha256)에 실제 파일 hash를 남겼다.
- app tree: `ff163eaaab6fbf214b87f76c1edb133cc9edd4d6`; api tree: `3d0f3e16e0f55ad4c593568dae8262f3ffbad55d`. 빌드 전후 원본과 일치한다.

| 실행 | 실제 결과 |
|---|---|
| `flutter pub get --enforce-lockfile` | exit 0, 기존 lockfile 유지. 최초 실행 약 24초 |
| `flutter build apk --debug --flavor production --no-pub` | 성공한 의존성 해석 뒤 실행. exit 0, 첫 전체 실행 약 451초 |
| `bash tools/nowia/build-cloud.sh` | exit 0, wrapper 전체 18초, Gradle 약 9.4초. 같은 환경의 cache 사용 재실행 |
| wrapper 26개 기록 단계 | 모두 exit 0, timeout 없음. APK 서명과 source/lock 검증 포함 |

현재 설치된 도구로 저장소 루트에서 재빌드한다.

```bash
bash tools/nowia/build-cloud.sh
```

새 도구 설치 절차는 [Cloud APK runbook](runbooks/cloud-apk-build.md)을 따른다. FND-04에서 `setup-cloud.sh`와 하위 Android 설치 스크립트를 빈 도구 경로에서 실제 실행했고 전체 설치·분석·테스트·APK를 재현했다. 기존 호스트의 생성 캐시 일부는 재현 공간 확보를 위해 정리했으며 재빌드 시 다시 다운로드될 수 있다.

## 검증한 APK

| 항목 | 결과 |
|---|---|
| 다운로드 사본 | `build/artifacts/butterfly-v2.6.0-production-debug.apk` |
| Flutter 원 출력 | `app/build/app/outputs/flutter-apk/app-production-debug.apk` |
| 크기 | 219,409,984 bytes (약 209.25 MiB) |
| SHA-256 | `da100dbcde47a4b8d03c3ef1e0cbce869146a5ca2beaf929babf2bedf1263c5b` |
| 패키지 / 이름 / 버전 | `dev.linwood.butterfly` / Butterfly / `2.6.0+199` |
| compile / target / min SDK | `36 / 36 / 24`, 실제 APK manifest 확인 |
| ABI | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| 서명 | `apksigner verify --verbose --print-certs` exit 0, APK v2, Android Debug 인증서 |

첫 빌드와 wrapper 재실행의 APK hash가 동일하다. 이 비교는 같은 환경·cache·debug key를 사용한 두 실행에 한정된다. 새 환경 간 byte 단위 동일성 검증은 아니다. debug key는 저장소나 인계 자료에 포함하지 않는다.

원본 applicationId와 debug 서명을 유지했다. 공식 Butterfly와 서명이 달라 업데이트 설치가 충돌할 수 있으므로 기존 앱·노트를 삭제해서 시험하지 않는다. debug 성능과 실기기 필기 품질은 별도 검증 대상이다.

## 실제 도구와 환경 보완

| 대상 | 실제 사용/확인 값 |
|---|---|
| Flutter / Dart | `3.47.5` / `3.13.4`; Flutter SHA `6a19cca56475dbfba1478ee68d7bd0c2ef891da1` |
| JDK / javac | Temurin `21.0.12.1+1`; Flutter가 이 JDK를 선택함을 doctor로 확인 |
| Gradle / AGP / Kotlin plugin | 원본 `9.7.1 / 9.4.0 / 2.4.20` 설정으로 빌드 완료 |
| SDK / build-tools / NDK | API 36 rev2, 의존성용 API 35 rev2 / `36.0.0` / `28.2.13676358` |
| CMake / platform-tools | `3.22.1` / `37.0.1` |
| Android 도구 | command-line tools `23.0`, 별도 bootstrap CLI `1.0.16500706` |
| Rust | 앱 wrapper `1.98.1`; OneNote 의존성 자체 pin `1.98.0`으로 native hook 실행 |

이전 tar 소유권 오류는 `TAR_OPTIONS=--no-same-owner`로 해결했다. Java에는 관리형 proxy와 호스트 CA trust를 전달했다. SDK 라이선스는 실제 설치가 생성했고 Android doctor도 수락 상태를 확인했다. API 35와 CMake는 첫 실제 빌드에서 자동 설치된 요구 조건을 재현 절차에 반영했다. 원본 앱·API·lockfile·추적 생성 코드는 변경하지 않았다.

## 증거와 남은 조건

[재개 실행 보고서](evidence/FND-03-resume.md), [기계 판정](evidence/resume-build/apk-verification.json), [wrapper 결과](evidence/resume-build/wrapper/result.json)에 명령·exit·timeout·도구·APK·source 정보를 보존한다. 실행마다 독립 증거 디렉터리를 만들고 실패 후에도 source/lock을 확인한다. 이전 실패 기록은 [기존 FND-03 보고서](evidence/FND-03.md)에 그대로 남아 있다.

FND-03은 **VERIFIED (미병합)**다. FND-04의 새 컨테이너 결과는 아래와 같으며 별도 Codex task·환경 publish는 NOT_RUN이다. FND-05는 정상 push/PR CI 및 의도한 실패 job·APK 다운로드 대조를 완료해 VERIFIED다. FND-04는 ADR-006의 대체 경로로 VERIFIED, G0는 ACCEPTED다. APP-01은 WAITING_DEVICE, G1은 NOT_ACCEPTED다. [초안 PR #1](https://github.com/Refstop/Nowia/pull/1)은 미병합이다.

## FND-04 새 컨테이너 재현

실행 source `c46c32f66534db09a144ce31000fd502282dd00a`, Ubuntu 26.04의 새 파일시스템·홈·도구·캐시에서 `setup-cloud.sh` → `quality-gate.sh` → `build-cloud.sh`를 실행했다. 기존 개발 도구·캐시는 mount하지 않았다. 기본 OS 패키지 이미지는 준비 단계 캐시를 재사용했고 같은 컨테이너 내 각 단계가 만든 캐시는 다음 단계에서 사용했다.

- 전체 컨테이너 exit 0, 약 12분 28초. setup exit 0, 엄격한 app/API 분석 진단 0, API 46개·app 363개 테스트 PASS.
- 빌드 wrapper 26개 단계 exit 0, timeout 없음. 실제 APK build 단계 약 419.5초, Gradle 보고 417.6초.
- APK: `/workspace/fnd04-repro/artifacts/butterfly-v2.6.0-production-debug.apk`, 219,408,832 bytes.
- SHA-256: `e05e1dab8afa56cb99ec539b6fa8a83203b71dbe9f330fae0cc151cb0f2f50d9`.
- 동일 package·버전·SDK·ABI, APK v2 서명 검증 PASS. 새 debug 인증서 SHA-256은 `343b5d297e55e1f0ef9c85b2309dfebf46dcfa2f59737419dff7822634a5bb9d`다.
- 빌드 전후 source/lockfile PASS, Git 상태 깨끗함. 앱/API 원본 변경 없음.

환경별 debug key가 다르므로 과거 APK와 byte 단위 동일성을 주장하지 않는다. 같은 호스트의 독립 컨테이너 검증이며 Cloud publish·별도 Codex task나 GitHub runner 검증을 대신하지 않는다. [전체 보고서](evidence/FND-04-05.md)와 [기계 결과](evidence/fnd04-05/cold/build/result.json)를 확인한다.

## FND-05 원격 CI와 APK 다운로드

정상 push [38382711491](https://github.com/Refstop/Nowia/actions/runs/38382711491) 및 PR [38382751680](https://github.com/Refstop/Nowia/actions/runs/38382751680)은 SUCCESS다. PR head `de79ee491bc95938357689ab3053537f215ef01e`와 실제 checkout `6f83f51a65938fe5535ef865ff25fd4141bc3120`의 tree는 동일하다. 새 GitHub-hosted runner에서 도구 설치, 엄격한 분석, 409개 테스트, APK 빌드·서명·source/lock 보존을 통과했다.

PR CI APK는 219,409,992 bytes, SHA-256 `ab5d88c3cc614e152431da8a14fa5f73839f4e2378fdd56073899fd1df47a4de`다. 별도 [다운로드 검증 job](https://github.com/Refstop/Nowia/actions/runs/38384463103)이 원래 artifact를 실제 내려받아 크기·hash를 대조했다. 이 다운로드는 별도 GitHub job에서 실행했으며 현재 작업 공간에 같은 대용량 APK를 내려받았다는 의미는 아니다. 무결성·독립 Dart AOT 컴파일 실패도 각각 실제 실패 job으로 전파됐다. 상세 artifact ID, ZIP hash, APK 인증서 및 실행 범위는 [FND-05 보고서](evidence/FND-05-ci.md)를 따른다.

기존 [기기 시험 안내](runbooks/device-baseline.md)는 위 FND-03 APK를 계속 사용한다. 서로 다른 환경의 debug 서명키를 혼동하지 않는다.
