# Cloud에서 Butterfly 원본 검사·APK 빌드 재현

기록: 2026-10-13 KST. Linux x86_64 관리형 Cloud에서 **새 도구 설치 → 정적 분석·테스트 → 원본 APK 빌드**를 수행하는 절차다. 원본은 Butterfly `v2.6.0`, commit `1e4c86b91f4d64361a73598bda0acc587f9381b0`이며 `app/`, `api/`, lockfile을 변경하지 않는다.

현재 작업 공간에서의 FND-03 APK 성공과 이번 새 컨테이너 재현은 별도 실행이다. 새 컨테이너의 설치·분석·409개 테스트·APK 빌드·서명·원본 보존 검증은 모두 통과했다. 최종 결과·hash는 해당 실행의 `build/result.json`과 [빌드 기준선](../build-baseline.md)을 따른다. Cloud 설정 publish·새 Codex 작업 재현과 원격 GitHub Actions 실행은 **NOT_RUN**이다.

## 고정 도구와 네트워크

| 도구 | 값·출처 |
|---|---|
| Flutter / Dart | `3.47.5` / `3.13.4`, Flutter revision `6a19cca56475dbfba1478ee68d7bd0c2ef891da1` |
| JDK / javac | Temurin `21.0.12.1+1`, 공식 `adoptium/temurin21-binaries` release |
| Android command-line tools | `23.0`, Google `commandlinetools-linux-16111833_latest.zip` |
| Android CLI | 이번 설치 `1.0.16500706`; 위 launcher가 별도 다운로드 |
| Android SDK | API `36`·`35`, 이번 platform revision 각각 `2`; build-tools `36.0.0`, platform-tools `37.0.1` |
| NDK / CMake | `28.2.13676358` / `3.22.1` |
| rustup installer / Rust | 버전별 archive `1.29.1` / 앱 compiler `1.98.1` |
| OneNote 의존성 Rust | 의존성 자체 pin `1.98.0`; 앱의 pin과 구분 |
| Gradle / AGP / Kotlin | 원본 설정 `9.7.1` / `9.4.0` / `2.4.20` |

[toolchain-env.sh](../../tools/nowia/toolchain-env.sh)가 setup·quality·build에 공통으로 적용된다. `NOWIA_TOOLCHAIN_ROOT`는 절대 경로이며 기본값은 저장소 상위의 `toolchains`다. `JAVA_HOME`, `ANDROID_HOME`, `CARGO_HOME`, `RUSTUP_HOME`, `PUB_CACHE`, `GRADLE_USER_HOME`을 이 루트 아래로 지정한다. 네이티브 hook은 별도의 기본 사용자 캐시를 만들 수 있으므로 모든 캐시가 이 루트 안에 있다고 가정하지 않는다.

관리형 `HTTP_PROXY`·`HTTPS_PROXY`와 CA를 유지한다. 공통 환경 스크립트가 Java proxy와 trust store(`/etc/ssl/certs/java/cacerts`, 필요하면 `NOWIA_JAVA_TRUST_STORE`)를 설정한다. TLS 검증을 끄지 않는다. `TAR_OPTIONS=--no-same-owner`는 컨테이너의 tar 소유권 변경 오류를 방지한다. Docker에서는 관리형 Docker client가 제공하는 컨테이너용 proxy를 사용하며 외부 셸의 proxy 주소로 덮어쓰지 않는다.

## 빈 도구 디렉터리에서 시작

Git, curl, Python 3, tar, unzip, xz와 기본 C/C++ 빌드 도구가 필요하다. 재현 컨테이너에 사용하는 패키지 목록은 [Dockerfile](../../tools/nowia/container/Dockerfile)에 있다. 공식 배포 호스트·Dart/Gradle/Rust 패키지 저장소 접근도 필요하다.

저장소 루트에서 다음을 실행한다. 실행별 새 경로를 사용하고 단계가 실패하면 원인을 확인한 뒤 다시 시작한다. 아래는 wrapper 사용 절차이며, 예시 경로의 실행 결과를 미리 보장하지 않는다.

```bash
set -euo pipefail
nowia_run_id="$(date -u +%Y%m%dT%H%M%SZ)"
export NOWIA_TOOLCHAIN_ROOT="/workspace/toolchains-$nowia_run_id"
export NOWIA_SETUP_EVIDENCE_DIR="$PWD/build/nowia-evidence/$nowia_run_id/setup"

bash tools/nowia/setup-cloud.sh
bash tools/nowia/quality-gate.sh \
  --evidence "$PWD/build/nowia-evidence/$nowia_run_id/quality"
NOWIA_EVIDENCE_DIR="$PWD/build/nowia-evidence/$nowia_run_id/apk" \
  bash tools/nowia/build-cloud.sh
```

[setup-cloud.sh](../../tools/nowia/setup-cloud.sh)는 비어 있는 도구 루트만 받으며 기존 설치를 덮어쓰지 않는다. 설치 증거 경로도 새 경로여야 한다. Android/JDK 설치 → Flutter clone·전체 revision 확인 → rustup checksum 확인·Rust 설치 → Android precache·doctor → 원본 검증 순서다. Android SDK 설치 명령에는 라이선스 수락이 포함되며 선택적 CLI metrics는 끈다.

설치가 중단되어 도구 디렉터리가 일부 채워졌다면 같은 경로에 setup을 반복하지 않는다. 로그를 보존하고 다음 시도에는 새 도구·증거 경로를 지정한다. 준비된 도구를 재사용하려면 다음 절의 quality/build를 실행한다.

### 다운로드 검증 범위

- JDK SHA-256: `ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94`. FND-03에서 받은 공식 release checksum과 일치하는 값을 검사한다.
- Android command-line tools SHA-1: `e025545c62a8e64c7559119566a569fb1dec5f60`(Google repository metadata), SHA-256: `0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8`. 두 값 모두 검사한다.
- rustup은 [버전 1.29.1 archive](https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-unknown-linux-gnu/rustup-init)를 받으며 SHA-256 `dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71`을 검사한다. 가변 `rustup/dist/` 경로를 사용하던 수동 절차를 대체했다. 이 checksum의 출처는 FND-03 관찰 bytes이며 별도 서명 검증을 수행했다는 뜻은 아니다.
- `platform-tools`, API 35·36 platform revision은 실행 시점에 따라 달라질 수 있다. command-line tools의 Android CLI bootstrap도 `android/cli/latest/` 경로를 사용한다. launcher ZIP checksum은 이 별도 CLI와 SDK의 모든 bytes를 고정하지 않는다. 실제 버전은 `setup/android/setup.log` 및 빌드의 `sdk-packages.log`에 기록된다.
- Docker base image는 digest로 고정하지만 apt 패키지는 설치 시점의 저장소를 사용한다. `host-packages.tsv`에 결과를 기록한다. 새 환경의 debug 서명키도 달라질 수 있으므로 환경 간 APK hash 동일성을 완료 조건으로 삼지 않는다.

## 준비된 환경에서 검사·재빌드

```bash
export NOWIA_TOOLCHAIN_ROOT=/workspace/toolchains
python3 tools/nowia/verify_baseline.py
bash tools/nowia/quality-gate.sh
bash tools/nowia/build-cloud.sh
```

이미 분석·테스트를 통과했고 새 변경이 없다면 APK 재빌드 명령만 실행할 수 있다. 현재 호스트의 일부 의존성 캐시는 이번 작업에서 정리했으므로 기존 도구 설치를 재사용하더라도 pub/Gradle/Rust 자료를 다시 다운로드할 수 있다.

[quality gate](../../tools/nowia/quality-gate.py)는 앱/API의 `pub get --enforce-lockfile`, `--fatal-infos` 정적 분석, 기존 API·앱 테스트, 실행 전후 원본 검증을 수행한다. 테스트 동시 실행 수는 2다. 기본 증거는 `build/nowia-evidence/quality-<임의문자>/`이고 `--evidence`로 새 디렉터리를 지정할 수 있다.

[build wrapper](../../tools/nowia/build-baseline.sh)는 도구를 업그레이드하지 않는다. 도구·원본 확인 뒤 `flutter pub get --enforce-lockfile`, 원본 재검증, `flutter build apk --debug --flavor production --no-pub`를 실행한다. `--no-pub`는 lockfile 검증 성공 뒤 사용한다. 실패·timeout도 기록하고 원본을 다시 확인하며 오래된 APK를 새 결과로 인정하지 않는다. 기본 증거는 `build/nowia-evidence/<UTC시각>-<임의문자>/`이고 `NOWIA_EVIDENCE_DIR`로 존재하지 않는 절대 경로를 지정할 수 있다.

Doctor 전체 경고와 실제 Android 빌드 결과는 구분한다. FND-03의 Chrome·Linux desktop 미설치와 `maven.google.com` 검사 경고는 당시 기록이고 Android 도구·실제 Gradle 다운로드는 별도 검증했다. 후속 실행은 자체 doctor·빌드 로그로 판정한다. OneNote native hook의 Rust `1.98.0` 다운로드 역시 실패·성공을 해당 실행 로그로 확인하며 의존성 pin을 바꿔 우회하지 않는다.

## 새 Docker 컨테이너에서 재현

[reproduce-container.sh](../../tools/nowia/reproduce-container.sh)는 로컬 Docker daemon(`/var/run/docker.sock`)과 관리형 proxy·CA가 있는 환경용이다. 새 컨테이너·home·도구·캐시를 만들고 커밋된 source를 `git clone --no-local`로 복사해 해당 SHA에 고정한다. 호스트 소스·CA는 읽기 전용이며 호스트의 Flutter/pub/Gradle/Rust 캐시를 전달하지 않는다.

원하는 변경을 커밋해 `git status --porcelain`이 비어 있어야 한다. 출력 경로는 절대 경로이고 이전 실행과 겹치면 안 된다. 긴 빌드는 시작과 대기를 분리할 수 있다.

```bash
bash tools/nowia/reproduce-container.sh start /workspace/fnd04-repro-next
bash tools/nowia/reproduce-container.sh wait /workspace/fnd04-repro-next
```

`start` 성공은 컨테이너 시작만 뜻한다. `wait`가 최종 컨테이너 exit code를 그대로 반환하고 상태·종료 코드를 저장한다. 동기식 대안은 아래 한 명령이다. 위 실행과 별개의 새 출력 경로를 사용한다.

```bash
bash tools/nowia/reproduce-container.sh run /workspace/fnd04-repro-next-sync
```

base image만 준비하려면 `prepare /workspace/fnd04-image-check`를 사용한다. `prepare` 역시 새 증거 디렉터리를 만들므로 후속 `start`는 다른 출력 경로를 사용한다. `wait`만 이미 생성된 실행 경로를 받는다. 컨테이너 안의 순서는 `setup-cloud.sh → quality-gate.sh → build-cloud.sh`이며 각 단계 실패 시 뒤 단계를 실행하지 않는다.

| Docker 출력 디렉터리 아래 | 확인할 증거 |
|---|---|
| `source-commit.txt`, `clone-status.txt`, `isolation.txt` | 커밋 SHA, 깨끗한 clone, 새 도구·home 캐시 확인 |
| `image-build.log`, `image-id.json`, `host-packages.tsv`, `container-mounts.json` | base image, 설치 패키지, 호스트 mount 범위 |
| `setup/`, `setup-exit-code.txt` | 설치 로그·checksum 검사·실제 버전·exit code |
| `quality/result.json`, `quality/*-test.log`, `quality-exit-code.txt` | 분석·테스트·원본 보존 판정과 개별 명령 결과 |
| `build/result.json`, `build/apk-*.log`, `build-exit-code.txt` | APK 빌드·SHA-256·서명·manifest·원본 보존 결과 |
| `artifacts/butterfly-v2.6.0-production-debug.apk`, `artifacts/apk.sha256` | 성공 후 복사한 APK와 hash |
| `run.log`, `container.log`, `container-exit-code.txt`, `container-state.json` | 전체 실행·컨테이너 종료 결과 |

직접 빌드의 APK 원 출력은 `app/build/app/outputs/flutter-apk/app-production-debug.apk`다. production 식별자는 `dev.linwood.butterfly`이고 debug 서명은 기존 공식 앱 또는 다른 환경의 debug APK와 다를 수 있다. 설치 충돌을 기존 앱·노트 삭제로 해결하지 않는다. [태블릿 시험 안내](device-baseline.md)를 따른다.

## 실제 확인 범위와 원격 CI

현재 `/workspace/fnd04-repro`는 commit `c46c32f66534db09a144ce31000fd502282dd00a`를 새 컨테이너에서 실행한 증거다. setup·quality·build·컨테이너 모두 exit 0이다. 정적 분석 및 **API 46개 + 앱 363개 = 409개 테스트 PASS**, APK 빌드·서명·실행 후 source 검증 PASS를 확인했다. 빌드 wrapper의 26개 단계도 모두 exit 0이다. FND-03의 이전 APK와 구분되는 이번 산출물은 다음과 같다.

| 항목 | 새 컨테이너 결과 |
|---|---|
| APK | `/workspace/fnd04-repro/artifacts/butterfly-v2.6.0-production-debug.apk` |
| 크기 | 219,408,832 bytes |
| SHA-256 | `e05e1dab8afa56cb99ec539b6fa8a83203b71dbe9f330fae0cc151cb0f2f50d9` |
| debug 인증서 SHA-256 | `343b5d297e55e1f0ef9c85b2309dfebf46dcfa2f59737419dff7822634a5bb9d` |

FND-03 APK와 인증서·hash가 다르므로 두 APK를 같은 서명의 업데이트 파일로 취급하지 않는다. 이는 새 환경의 빌드 성공·원본 보존 재현이며 APK bytes의 동일성 검증은 아니다.

[GitHub Actions workflow](../../.github/workflows/nowia-baseline.yml)는 `main` PR·push, `task/fnd-*` push와 수동 실행을 지원한다. 매 job마다 빈 toolchain에서 같은 setup·quality·build를 수행한다. 증거 artifact는 성공·실패 모두 보관하고 APK artifact는 앞 단계 성공 후 보관한다. 수동 `failure_probe=integrity` 또는 `compile`은 의도된 오류를 발생시켜 **job 실패가 예상 결과**다. 실제 CI 완료에는 정상 실행의 APK 다운로드·hash 대조와 각 probe의 의도된 오류·실패 상태 확인이 필요하다. 로컬 probe 성공만으로 원격 job 실패를 검증했다고 하지 않는다.

현재 GitHub 연결의 `Refstop/Nowia` 쓰기 요청은 HTTP 403으로 거절되어 원격 반영·Actions 실행 검증은 완료하지 못했다. 정확한 연결 권한 원인은 확정하지 않는다. Cloud 환경 설정 publish와 별도 새 Codex 작업 검증도 NOT_RUN이다. 새 Docker 컨테이너 결과, 새 Codex 작업, 원격 CI, APP-01 실기기 결과는 각각 구분해 [현재 상태](../status.md)에 기록한다. APP-01/G1은 기기 시험 전까지 WAITING_DEVICE다.
