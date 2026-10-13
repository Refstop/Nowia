# 원본 APK CI와 증거 확인

2026-10-13 KST: **정상 push·PR CI, 두 가지 의도된 실패 job, 원본 APK artifact 다운로드·SHA-256 대조를 검증했다.** FND-05는 VERIFIED다. [ADR-006](../adr/ADR-006-ci-reproduction.md)의 CI 대체 재현 경로 채택으로 FND-04도 VERIFIED, G0는 ACCEPTED다. [PR #1](https://github.com/Refstop/Nowia/pull/1)은 draft·미병합이다. Codex Cloud 설정 publish·별도 새 Codex 작업은 NOT_RUN이며, APP-01/G1은 WAITING_DEVICE/NOT_ACCEPTED다.

이전 문서의 원격 NOT_RUN·HTTP 403 BLOCKED는 접근 복구 전 기록이다. [접근 복구 기록](../evidence/fnd05-ci/access-restored.json), [게시 기록](../evidence/fnd05-ci/publication.json)에 실제 브랜치 생성·게시·PR을 남겼다. 과거 거절을 현재 원격 실행 상태로 해석하지 않는다.

## 검증한 실행

| 실행 | 실제 결과 | 증거 |
|---|---|---|
| [정상 PR 38382751680](https://github.com/Refstop/Nowia/actions/runs/38382751680) | SUCCESS. 엄격한 분석, API 46개 + 앱 363개 = 409개 테스트, APK 빌드·서명·원본 보존 PASS | [정상 실행 요약](../evidence/fnd05-ci/normal-pr-summary.json), [quality 결과](../evidence/fnd05-ci/normal-pr/quality/result.json), [APK 결과](../evidence/fnd05-ci/normal-pr/apk/result.json) |
| [정상 push 38382711491](https://github.com/Refstop/Nowia/actions/runs/38382711491) | SUCCESS. 같은 게시 head의 push trigger 검증 | [게시 기록](../evidence/fnd05-ci/publication.json) |
| [무결성 실패 38383269605](https://github.com/Refstop/Nowia/actions/runs/38383269605) | 예상된 job FAILURE, probe exit 1, 원래 source 사후 PASS. evidence 다운로드·hash 대조 PASS, APK artifact 없음 | [실패 결과 요약](../evidence/fnd05-ci/failure-probes.json), [integrity 결과](../evidence/fnd05-ci/integrity/probe-integrity/result.json) |
| [컴파일 실패 38383276918](https://github.com/Refstop/Nowia/actions/runs/38383276918) | 예상된 job FAILURE, probe exit 254, 원래 source 사후 PASS. evidence 다운로드·hash 대조 PASS, APK artifact 없음 | [실패 결과 요약](../evidence/fnd05-ci/failure-probes.json), [compile 결과](../evidence/fnd05-ci/compile/probe-compile/result.json) |
| [APK 다운로드 검증 38384463103](https://github.com/Refstop/Nowia/actions/runs/38384463103) | SUCCESS. 정상 PR run의 APK를 별도 job에서 다운로드해 크기·SHA-256 일치 확인 | [검증 run](../evidence/fnd05-ci/artifact-verification-run.json), [APK 대조 결과](../evidence/fnd05-ci/artifact-download/verification.json) |

정상 PR run의 head는 `de79ee491bc95938357689ab3053537f215ef01e`, **실제 빌드 checkout은 GitHub PR merge commit `6f83f51a65938fe5535ef865ff25fd4141bc3120`**이다. [commit-before.log](../evidence/fnd05-ci/normal-pr/apk/commit-before.log)에 기록됐다. PR head와 실제 빌드 revision을 혼용하지 않는다.

| 검증한 원본 APK artifact | 값 |
|---|---|
| 원 run / attempt | `38382751680` / `1` |
| artifact 이름 / ID | `nowia-upstream-debug-38382751680-1` / `11804603978` |
| APK 이름 / 크기 | `app-production-debug.apk` / 219,409,992 bytes |
| APK SHA-256 | `ab5d88c3cc614e152431da8a14fa5f73839f4e2378fdd56073899fd1df47a4de` |
| 다운로드 검증 source·hash | 모두 PASS |

약 209 MiB인 APK는 이 세션의 `download_file` 32 MiB 한도를 넘는다. 공식 `actions/download-artifact@v8.0.2`를 고정한 별도 GitHub job에서 **기존 artifact를 다운로드**해 검증했고, 작은 결과 JSON/TXT를 내려받아 보존했다. 다운로드를 대신할 APK 재빌드는 수행하지 않았다. 이 결과는 managed 작업 공간에 CI APK 전체를 다운로드했다는 뜻이 아니다. artifact ZIP의 digest·크기와 내부 APK의 SHA-256·크기는 다르며, 위 표는 APK 자체 값이다.

## workflow 구성

[nowia-baseline.yml](../../.github/workflows/nowia-baseline.yml)은 `main` 대상 PR, `main` 및 `task/fnd-*` push, 수동 실행에 반응한다. Ubuntu 26.04에서 임시 도구 경로를 새로 만들고 원본 검사 → runner 준비 → 도구 설치 → 엄격한 app/API 분석 → 기존 전체 테스트 → APK 빌드·서명·원본 재검사를 실행한다. 기존 캐시 복원은 없다. setup·quality·build 절차는 [Cloud 빌드 runbook](cloud-apk-build.md)을 따른다.

runner 준비 단계는 GitHub-hosted Ubuntu 26.04에 한정해 사용하지 않는 선설치 도구를 제거하고 필요한 Linux runtime package를 확인하며 24 GiB 이상 여유 공간을 요구한다. 개인 개발 환경이나 다른 runner에서 이 정리 명령을 그대로 실행하지 않는다.

baseline job은 `contents: read`만 사용하고 checkout 자격 증명을 보존하지 않는다. 실패를 `continue-on-error`로 무시하지 않는다. 증거는 성공·실패 모두 14일 보관하고 설치용 ZIP·tar.gz를 제외한다. 검증한 APK는 앞 단계 성공 후 별도 artifact로 14일 보관한다. 기존 서버·Agent 계약 기능이 없어 관련 검사는 N/A다. 고정 checkout/upload action SHA는 [검증 근거](../evidence/fnd04-05/host-quality/action-pins.json)를 따른다.

[다운로드 검증 workflow 사본](../evidence/fnd05-ci/verification-workflow.yml.disabled)은 `verification/fnd-05-artifact-download` 브랜치에 한정한 push와 수동 실행을 지원한다. `contents: read`, `actions: read` 권한으로 지정한 원 run·attempt·head·artifact를 확인하고 다운로드한 APK를 대조한다. `actions/download-artifact`는 `9000827ccba6bdab643e8b6fd33ac0654aef8333`(v8.0.2), upload는 `cf430e030ddbb5b0abf93d22962f4752f3646cd9`(v7.0.2)로 고정했다. 원 APK를 중복 업로드하지 않고 결과 JSON/TXT만 14일 보관한다.

## 이후 변경을 검증하는 재실행 절차

아래는 **다음 변경을 검증할 때의 절차**다. 위 표의 실제 완료 결과와 구분하며, 새 run마다 새로운 source SHA·run URL·artifact를 기록한다.

1. 검증할 변경을 `task/fnd-*` 브랜치에 게시하고 `main` 대상 PR을 갱신한다. 기존 PR #1의 미병합 상태를 확인하며, CI 실행을 위해 main에 자동 병합하지 않는다.
2. 정상 workflow의 분석·테스트·APK 단계를 확인한다. evidence와 APK artifact를 다운로드한다. 증거의 `apk/result.json`, `apk/apk-sha256.log`, `apk/apk-signature.log`, `apk/apk-manifest.log`, stage별 exit/timeout과 `apk/commit-before.log`의 실제 checkout을 확인한다.
3. 다운로드한 APK의 SHA-256을 **그 run**의 빌드 증거와 비교한다. 직접 다운로드가 가능한 GitHub UI/승인된 도구를 쓰거나, 위 다운로드 검증 workflow를 별도 `verification/fnd-05-artifact-download` 브랜치에 준비한다. 재사용 시 원 run·attempt·head·artifact 이름과 예상 SHA-256을 모두 새 증거로 갱신한다. 과거 로컬·다른 CI debug APK와 hash가 같아야 한다고 가정하지 않는다.
4. 실패 전파 검증이 필요한 workflow 변경이면 `failure_probe=integrity`, `failure_probe=compile`을 별도로 실행하고 **job 실패**를 확인한다. `workflow_dispatch` 등록에는 기본 브랜치에 workflow가 존재해야 한다. 현재처럼 미병합이면 정상 PR 브랜치를 그대로 두고 별도 `task/fnd-05-probe-*` 임시 브랜치에서 해당 probe 조건만 활성화해 push한다. 이번 실행은 이 방식으로 검증했다.
5. 각 실패 run의 evidence를 다운로드·hash 확인하고, `expected_failure_observed=true`, 원래 source 사후 PASS, 의도한 marker·오류 로그를 확인한다. 실패 run에 APK artifact가 없어야 한다. 단계가 다른 이유로 실패했다면 probe 통과로 보지 않는다.

`integrity`는 임시 worktree의 원본 파일에 합성 marker를 추가해 원본 검사를 실패시킨다. `compile`은 임시 standalone Dart AOT fixture를 컴파일해 실패시킨다. **Android 앱의 APK 컴파일 실패 시험은 아니다.** 둘 다 원래 app/API를 변경하지 않는다. 이번에는 로컬 exit code뿐 아니라 실제 GitHub job 실패와 evidence 다운로드까지 검증했다.

## artifact 판정 규칙

- source commit, 명령·도구 버전, 종료 코드·timeout, APK hash·서명·manifest, 원본·lock 검사 결과를 함께 보관한다.
- 실패·중단된 실행의 오래된 APK를 성공 산출물로 사용하지 않는다. artifact 보관 기간이 지나면 새 실행으로 증거를 다시 확보한다.
- debug key는 공개하지 않는다. 개인 필기, 비밀값, provider 자격 증명은 evidence에 넣지 않는다.
- FND-04/FND-05 VERIFIED 및 G0 ACCEPTED는 빌드·CI 기술 검증 판정이며 PR 병합·Codex 환경 publish·실기기 통과를 의미하지 않는다. Galaxy Tab S7 시험은 [기기 안내](device-baseline.md)에 따라 별도로 진행한다.
