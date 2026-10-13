# 원본 APK CI와 증거 확인

2026-10-13 KST: workflow와 로컬 품질 검사는 준비됐다. GitHub의 실제 정상 job, artifact 업로드·다운로드, 의도한 실패 job은 **NOT_RUN**이다. 학교 계정 `Refstop`의 저장소 관리자 역할과 별개로 연결 앱의 브랜치 생성 요청이 HTTP 403 `Resource not accessible by integration`으로 거절됐다. 실제 원격 브랜치·PR·병합은 없다.

## 구성

[nowia-baseline.yml](../../.github/workflows/nowia-baseline.yml)은 `main` 대상 PR, `main` 및 `task/fnd-*` push, 수동 실행에 반응한다. Ubuntu 26.04에서 임시 도구 경로를 새로 만들고 원본 검사 → 도구 설치 → 엄격한 app/API 분석 → 기존 전체 테스트 → APK 빌드·서명·원본 재검사를 실행한다. 기존 캐시 복원은 없다. 고정 action SHA는 [검증 근거](../evidence/fnd04-05/host-quality/action-pins.json)를 따른다.

`contents: read`만 사용하며 checkout 자격 증명을 보존하지 않는다. 실패를 `continue-on-error`로 무시하지 않는다. 증거는 성공·실패 모두 14일 보관하고 검증한 APK는 전체 성공 시에만 14일 보관한다. 기존 서버·Agent 계약 기능이 없어 관련 검사는 N/A다.

## 권한 해결 후 실행할 절차

아래는 원격 **미실행 절차**다. GitHub 연결의 대상 계정·저장소 접근과 실제 쓰기 권한을 확인한 뒤 진행한다. 토큰이나 debug signing key를 저장소에 넣지 않는다.

1. `task/fnd-04-05-ci` 브랜치를 push하고 `main` 대상 draft PR을 만든다. 실제 source SHA와 run URL을 기록한다.
2. 정상 workflow의 분석·테스트·APK 단계를 확인한다. evidence와 APK artifact를 각각 다운로드한다.
3. evidence의 `apk/result.json`, `apk/apk-sha256.log`, `apk/apk-signature.log`, `apk/apk-manifest.log` 및 stage별 exit/timeout을 확인한다. 다운로드한 APK의 SHA-256이 해당 run 증거와 같은지 비교한다. 환경이 다른 과거 debug APK와 hash가 같아야 한다고 가정하지 않는다.
4. 수동 실행의 `failure_probe=integrity`, `failure_probe=compile`을 각각 실행하고 **job이 실패**하는지 확인한다. 수동 실행 등록은 workflow가 기본 브랜치에 존재해야 하므로 원격 통합 상태를 먼저 확인한다. 현재 문서는 병합을 실행했다는 뜻이 아니다.
5. 실패 run에도 evidence가 있고 APK artifact는 없는지 확인한다. evidence의 `expected_failure_observed=true`, 원래 source 사후 PASS, 실제 원인 로그를 함께 확인한다.

`integrity`는 임시 worktree의 원본 파일에 합성 marker를 추가해 원본 검사를 실패시킨다. `compile`은 임시 standalone Dart AOT fixture를 컴파일해 실패시킨다. **Android 앱의 APK 컴파일 실패 시험은 아니다.** 둘 다 원래 app/API를 변경하지 않는다. 로컬 결과는 각각 exit 1, 254였으며 GitHub job 상태까지 검증한 것은 아니다.

## artifact 판정 규칙

- source commit, 명령·도구 버전, 종료 코드·timeout, APK hash·서명·manifest, 원본·lock 검사 결과를 함께 보관한다.
- 실패·중단된 실행의 오래된 APK는 성공 산출물로 사용하지 않는다.
- debug key는 공개하지 않는다. 개인 필기, 비밀값, provider 자격 증명은 evidence에 넣지 않는다.
- 원격 run ID·URL·artifact 다운로드 확인 전에는 FND-05를 VERIFIED로 표시하지 않는다. 물리적 기기 검증은 [기기 시험](device-baseline.md)으로 별도 진행한다.
