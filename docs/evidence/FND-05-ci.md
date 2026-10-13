# FND-05 — 실제 GitHub CI 및 artifact 검증

기록: 2026-10-13 KST. **정상 push/PR CI, 의도한 실패의 job 전파, APK artifact의 별도 다운로드·SHA-256 대조를 모두 검증했다.** FND-05는 VERIFIED, [ADR-006](../adr/ADR-006-ci-reproduction.md)에 따라 FND-04도 VERIFIED이며 G0는 ACCEPTED다. [초안 PR #1](https://github.com/Refstop/Nowia/pull/1)은 미병합이다. Codex 설정 publish·별도 Codex task는 NOT_RUN, APP-01은 WAITING_DEVICE, G1은 NOT_ACCEPTED다.

## 소스와 게시 경로

학교 계정 Refstop의 설치 접근을 사용자가 수정한 뒤 쓰기를 재검증했다. 추가 ChatGPT 재연결 없이 GitHub connector로 원격 게시했다. [접근 재검증](fnd05-ci/access-restored.json)과 [게시 기록](fnd05-ci/publication.json)을 보존한다. 초기 원격 `main`은 `b0ab030fa132028fee02b3e4210257d894dc5e00`이며 병합하지 않았다.

| 대상 | 식별자 |
|---|---|
| Butterfly v2.6.0 | `1e4c86b91f4d64361a73598bda0acc587f9381b0` |
| 게시 전 로컬 snapshot | `1b877f181ab1720d4a5eb2590eb7eaeab22b9a42` |
| 원격 정상 CI head | `de79ee491bc95938357689ab3053537f215ef01e` |
| PR job의 실제 checkout | `6f83f51a65938fe5535ef865ff25fd4141bc3120` — GitHub PR merge commit |
| 위 세 snapshot의 동일 tree | `5f6c46411d3afdd359c10081686f448700e1c3f9` |
| app 원본 tree | `ff163eaaab6fbf214b87f76c1edb133cc9edd4d6` |
| api 원본 tree | `3d0f3e16e0f55ad4c593568dae8262f3ffbad55d` |

connector 게시 commit은 독립 metadata를 갖는다. 동일 tree를 확인했으며 원래 로컬 import·복원·구현 이력은 로컬 브랜치와 bundle에 보존한다. 이 보고서를 추가하는 후속 commit은 문서·증거만 변경하며 `[skip ci]`를 사용한다. 전체 CI를 후속 문서 SHA에서 실행했다고 보고하지 않는다. 앱/API·lockfile·추적 생성 코드·빌드 도구·실행 workflow는 검증한 head와 같다.

## 실제 실행 결과

| 실행 | 최종 결과 | 확인한 내용 |
|---|---|---|
| [정상 push 38382711491](https://github.com/Refstop/Nowia/actions/runs/38382711491) | SUCCESS | 설치·분석·409개 테스트·APK·서명·원본 보존·artifact 업로드 |
| [정상 PR 38382751680](https://github.com/Refstop/Nowia/actions/runs/38382751680) | SUCCESS | 위 전체 단계 통과, 아래의 상세 증거 원본 실행 |
| [무결성 실패 38383269605](https://github.com/Refstop/Nowia/actions/runs/38383269605) | FAILURE — 의도한 결과 | 실제 프로세스 exit 1 → job 실패, 증거 업로드 성공, APK artifact 없음 |
| [컴파일 실패 38383276918](https://github.com/Refstop/Nowia/actions/runs/38383276918) | FAILURE — 의도한 결과 | 독립 Dart AOT 프로세스 exit 254 → job 실패, 증거 업로드 성공, APK artifact 없음 |
| [별도 APK 다운로드 38384463103](https://github.com/Refstop/Nowia/actions/runs/38384463103) | SUCCESS | 정상 PR run/artifact 확인 후 실제 다운로드, APK 크기·hash 일치 |

정상 runner는 GitHub-hosted Ubuntu 26.04다. 새 `RUNNER_TEMP` 도구·캐시 경로에서 설치하며 기존 개발 환경이나 다른 CI의 캐시를 복원하지 않는다. 같은 job의 선행 단계가 만든 캐시는 후속 단계에서 사용한다. OS 이미지·apt까지 모든 입력을 고정한 비트 재현 빌드는 아니다. runner 준비 후 실제 가용 공간은 116,511,637,504 bytes로 최소 24 GiB 검사를 통과했다.

`bash tools/nowia/setup-cloud.sh` → `bash tools/nowia/quality-gate.sh` → `bash tools/nowia/build-cloud.sh`를 실행했다. quality 12단계·build 26단계 모두 exit 0, timeout 없음, 엄격한 app/API 분석 진단 0, API 46개 + app 363개 = **409개 테스트 PASS**다. APK 빌드 명령은 `flutter build apk --debug --flavor production --no-pub`이며 약 430초가 걸렸다. 빌드 전후 source/lock 보존과 APK 서명도 PASS다.

[정상 실행 요약](fnd05-ci/normal-pr-summary.json), [setup](fnd05-ci/normal-pr/setup/setup.log), [quality](fnd05-ci/normal-pr/quality/result.json), [APK](fnd05-ci/normal-pr/apk/result.json), [manifest](fnd05-ci/normal-pr/apk/apk-manifest.log), [서명](fnd05-ci/normal-pr/apk/apk-signature.log)에 명령·exit·도구 버전·소스·APK 증거를 보존한다.

## APK와 artifact 구분

| 항목 | 확인한 값 |
|---|---|
| APK 파일 | `app-production-debug.apk` |
| APK 크기 | 219,409,992 bytes |
| APK SHA-256 | `ab5d88c3cc614e152431da8a14fa5f73839f4e2378fdd56073899fd1df47a4de` |
| package / 표시 이름 / 버전 | `dev.linwood.butterfly` / Butterfly / `2.6.0+199` |
| min / target / compile SDK | 24 / 36 / 36 |
| ABI | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| 서명 | APK v2 검증 PASS, Android Debug |
| debug 인증서 SHA-256 | `676162457cec2f56c214e3ffd56517758136a872a06f89865908ccdad951b115` |
| APK artifact | `11804603978`, `nowia-upstream-debug-38382751680-1` |
| APK artifact ZIP 크기 / SHA-256 | 219,410,154 bytes / `6d064c702f7f683081065ddf402cc530819a4080d16fd86360802d9b1d24dd08` |
| APK artifact 만료 예정 | 2026-10-27 19:34:35 KST (14일 보관) |

ZIP hash와 내부 APK hash는 서로 다른 값이다. 각 환경에서 생성한 debug key가 다르므로 FND-03·컨테이너·CI APK 간 byte 동일성을 주장하지 않는다. [기존 기기 시험](../runbooks/device-baseline.md)은 FND-03 APK/hash를 유지한다.

정상 PR의 증거 artifact `11804259587`은 65,534 bytes다. ZIP을 현재 작업 공간에 다운로드하고 SHA-256 `1730842d35889400091d9ca96b86be92174b314e8a405a83baa00edb9f84f2b2`를 대조한 뒤 `fnd05-ci/normal-pr/`에 풀었다.

## 실패 감지 증거

각 임시 검증 브랜치는 정상 head를 기반으로 해당 기존 probe 조건만 활성화했다. 정상 PR 브랜치와 main에 실패 조건을 반영하지 않았다.

| probe | 브랜치 / commit | 증거 artifact / ZIP SHA-256 |
|---|---|---|
| integrity | `task/fnd-05-probe-integrity` / `6fb26e00a0d53831ba71a460240fe457dbf54fe8` | `11804581732` / `1030b43a95bebd832b57c62c12bbc69bae7248d4e8f7cd02f1b20301af5e7985` |
| compile | `task/fnd-05-probe-compile` / `d07baa7f13671bcf11c6cdf143f10b044d895e70` | `11804796599` / `5c027cb6914d9ba30c80352d82e1ba0356552b3964c93853adba03a510159d80` |

두 증거 ZIP은 실제 다운로드·hash 대조 후 보존했다. `expected_failure_observed=true`, source-after PASS이며 APK artifact는 없다. 무결성 probe는 임시 검사 fixture, 컴파일 probe는 독립 Dart AOT 실패다. **Android APK 컴파일 실패 시험을 수행했다는 의미는 아니다.** [실패 요약](fnd05-ci/failure-probes.json)과 각각의 `integrity/`, `compile/` 로그가 근거다.

## 별도 APK 다운로드 검증

`verification/fnd-05-artifact-download` commit `b2cce3c8c6d6c37bbb850a1e8888a52b49415a1b`에서 별도 job을 실행했다. 정상 run `38382751680`의 repository·head·attempt·SUCCESS 및 artifact metadata를 확인하고, 공식 `actions/download-artifact` v8.0.2를 고정 SHA `9000827ccba6bdab643e8b6fd33ac0654aef8333`로 사용했다. ZIP digest 불일치는 오류로 처리한다. 실제로 내려받은 APK의 크기와 SHA-256이 위 빌드 증거와 일치했다. 재빌드는 하지 않았다.

실행은 2026-10-13 19:36:06–19:36:19 KST다. 이 대용량 APK 다운로드는 **별도 GitHub job에서 실행**했다. 현재 작업 공간에는 작은 검증 증거 ZIP을 다운로드했다. 검증 artifact `11805215417`은 914 bytes, ZIP SHA-256 `a8538326188c0c3cec271dbd56b6021bb14cc7df1a180737a4c1ee8f041dbaae`와 일치했다.

[검증 JSON](fnd05-ci/artifact-download/verification.json), [검증 run metadata](fnd05-ci/artifact-verification-run.json), [실행 workflow 보존본](fnd05-ci/verification-workflow.yml.disabled)을 확인한다. 검증 전용 브랜치는 제품 PR에 포함하지 않는다. 모든 보존 파일은 [SHA256SUMS.json](fnd05-ci/SHA256SUMS.json)으로 확인한다.

## 남은 작업

- APP-01: Galaxy Tab S7에서 S Pen·한글·저장·종료 후 복원 시험. 결과 없이 G1을 승인하지 않는다.
- PR 검토·병합: 초안 PR만 생성했고 main은 변경하지 않았다.
- Codex 설정 publish·새 Codex task는 미실행 상태를 유지한다. FND-04의 승인 경로는 ADR-006에 기록한 실제 GitHub CI 대체 경로다.
