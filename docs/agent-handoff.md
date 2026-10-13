# Nowia 다음 에이전트 배정

현재 범위는 FND-04·05와 APP-01 준비다. 제품 기능을 추가하지 않고 고정 upstream의 원본 debug APK 재현과 증거를 남긴다. 현재 상태·빌드 결과는 [status.md](status.md), [build-baseline.md](build-baseline.md)를 확인한다. 2026-10-13 브랜치는 `task/fnd-04-05-ci`, 새 컨테이너에서 실제 실행한 구현 commit은 `c46c32f66534db09a144ce31000fd502282dd00a`다. 인계 복원 commit `d1feecc5beecc21bb30901135f6d9eca04b9c94c`와 과거 SHA는 출처이며 현재 checkout과 구분한다.

FND-03은 VERIFIED다. FND-04는 빈 도구·캐시의 새 컨테이너에서 설치·분석·409개 테스트·APK·서명·원본 검사를 통과했다. [FND-04·05 보고서](evidence/FND-04-05.md)를 따른다. Cloud 설정 publish·별도 Codex task는 미실행이며 G0를 승인하지 않았다. FND-05 원격 접근은 사용자 GitHub 설치 설정 수정 후 Refstop 계정의 브랜치 생성으로 재검증했다. 이전 403은 해결됐으며 원격 CI를 진행한다. 최신 상태는 status.md를 따른다.

다음 순서: 정상 CI 및 artifact 다운로드 → 의도한 실패 job 검증. [CI runbook](runbooks/ci-baseline.md)에 절차가 있다. APP-01은 [기기 시험](runbooks/device-baseline.md)과 [결과 양식](runbooks/device-results-template.md)이 준비됐으며 WAITING_DEVICE다. 기존 시험 안내는 FND-03 APK/hash를 사용한다. 새 컨테이너 APK는 다른 debug key를 사용하므로 설치 파일을 혼동하지 않는다.

## 작업 시작 규칙

1. `AGENTS.md`, [project-inputs.md](project-inputs.md), 담당 티켓·ADR·증거를 읽는다.
2. `git status`, 기준 commit, 선행 티켓의 통합·검증 결과를 확인한다. import 기준은 `aad94d6f5d5de8f984ca90e3665895feeb092779`, upstream은 `1e4c86b91f4d64361a73598bda0acc587f9381b0`다. 실제 작업은 최신 통합 SHA를 명시하고 시작한다.
3. 독립 브랜치/worktree와 쓰기 허용 경로를 지정한다. 생성 코드·lockfile·공유 wrapper·schema/migration은 담당자 한 명이 소유한다.
4. 선행 조건은 단순 착수가 아니라 필요한 검증을 통과하고 통합된 상태다. 로컬 준비·원격 push·PR·병합을 구분한다.

## 위임 표

| 티켓·담당 | 선행 | 허용 범위 | 완료 기준·증거 | 중단·대기 조건 |
|---|---|---|---|---|
| FND-01 / LEAD | 없음 | 입력·상태·근거 문서 | 저장소 상태, D01~09 확정/미확정, M0 착수 입력 | 접근 실패나 미확정 값을 숨기지 않음 |
| FND-02 / BUILD+LEAD | FND-01 | upstream import, ADR-001, provenance·license 문서 | 태그→전체 SHA, source tree 비교, thin fork baseline, 변경 경계 | 기존 사용자 변경 덮어쓰기·라이선스 누락 금지 |
| FND-03 / BUILD | FND-02 | setup/build wrapper, 빌드 문서·evidence | 제품 변경 없는 debug APK, 명령·exit code·도구 버전·source SHA·APK hash·로그 | 최초 실패 단계 기록. 전체 의존성 업그레이드로 환경 오류를 덮지 않음 |
| FND-04 / BUILD-CLOUD | FND-03 | Cloud 환경 설정·wrapper·문서 | 연결·publish 및 새 task에서 분석/검사/APK 재현. 대체 CI는 실제 검증 후 ADR | 현재 managed 환경은 사용 가능. 이 환경의 APK 빌드만으로 publish·후속 새 task 검증을 완료 처리하지 않음 |
| FND-05 / BUILD+QA | FND-03 | CI, AGENTS, PR template, artifact 규칙 | 정상 APK artifact 다운로드와 의도한 fixture/compile 실패의 job 실패 확인 | 기존 오류를 광범위 `continue-on-error`로 숨기지 않음. 없는 서버·계약 검사는 N/A |
| APP-01 / APP+기기 QA | FND-03 | 기기 fixture·체크리스트·시험 증거 | 공식 앱/자체 baseline 비교, 펜·한글·저장·재실행 시험, 적합성 판정 | 기기 없으면 WAITING_DEVICE. 데이터 유실 시 사본 보존 후 해당 문서 시험 중지 |
| CORE-01 / CORE+BACKEND+LEAD | FND-02 | 계약·ADR-002~005·valid/invalid fixture | 실제 모델 확장 경로 확인, ID/revision/영역/snapshot/unknown field 의미 합의 | 설계 초안은 가능. 미통과 build/device gate를 통과한 것으로 가정해 기능 확대 금지 |
| CORE-02 / CORE+QA | FND-03, CORE-01 | 왕복 fixture·의미 비교기·호환 증거 | 펜/텍스트/Markdown/이미지/PDF/페이지/영역/extra 보존 | 정보 유실 시 저장 설계 수정이 우선 |

FND-03 이후 FND-04·FND-05·APP-01을 병렬 배정할 수 있다. 단, Cloud 접근이 없으면 FND-04는 대기 상태를 유지한다. CORE-01은 FND-02 이후 계약 초안을 준비할 수 있다. W0~W8 묶음은 달력이나 무조건 병렬 실행 지시가 아니며 각 티켓의 선행 조건이 우선한다.

후속 의존성: `CORE-02 → CORE-03 → CORE-04/CORE-05`, `CORE-02 + CORE-03 → APP-02`, `CORE-04 + APP-02 → APP-03`. APP-06은 APP-05와 저장 내구성 검증 뒤에 진행한다.

## 게이트와 상태

| 게이트 | 통과 증거 | 대체할 수 없는 항목 |
|---|---|---|
| G0 | 고정 upstream 원본 APK + 새 환경 재현 | upstream CI 메타데이터, release APK 다운로드, 기존 환경 1회 성공만으로 완료 불가 |
| G1 | Galaxy Tab S7에서 실제 펜·한글·저장 적합성 | APK 빌드, 에뮬레이터, ADB 목록만으로 완료 불가 |
| G2 | G0/G1을 전제로 ID·PKM 왕복·명령/undo·snapshot 계약 검증 | 계약 문서만으로 데이터 보존 완료 불가 |

상태는 `READY → IN_PROGRESS → REVIEW → VERIFIED → MERGED`, 예외는 `BLOCKED`, `WAITING_DEVICE`, `WAITING_DECISION`, `REJECTED`로 관리한다. 게이트 `ACCEPTED`와 티켓 `MERGED`는 별개다. 실패와 미실행을 성공으로 바꾸지 않는다.

## 전달 양식

```text
담당 티켓 / 기준 commit / 브랜치:
선행 티켓과 검증·통합 근거:
쓰기 허용 경로 / 공통 파일 소유자:
관련 ADR·fixture / 작업 범위 밖:
완료 조건 / STOP 조건:

결과 commit·PR·병합 상태:
변경 이유와 diff 요약:
정확한 검증 명령·exit code·로그:
APK 경로·SHA-256·build mode·source SHA:
PASS / FAIL / NOT_RUN / N/A 항목:
실기기·사용자 결정 대기 / 다음 의존성:
```

외부 OCR·AI 전송은 정책상 기본 OFF다. 실제 provider 호출·유료 API·실제 필기 업로드를 활성화하지 않는다. 전송 차단 코드가 존재한다는 의미로 보고하지 않는다.
