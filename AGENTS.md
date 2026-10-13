# Nowia 에이전트 작업 규칙

Nowia는 Note with Agent의 줄임말이다. Android 태블릿용 Butterfly thin fork를 기반으로 자유 캔버스 필기와 외부 Agent 읽기 연동을 준비한다.

## 작업 전

- `docs/project-inputs.md`, `docs/status.md`, `docs/build-baseline.md`, `docs/agent-handoff.md`와 담당 티켓·ADR·fixture를 읽는다. 파일이 없거나 내용이 미확정이면 완료로 가정하지 않는다.
- `git status`와 기준 commit, 선행 티켓 검증·통합 상태를 확인한다. 기존 사용자 변경을 임의로 되돌리지 않는다.
- 독립 브랜치/worktree, 담당 티켓, 쓰기 허용 경로를 지정한다. 다른 에이전트와 같은 파일을 동시에 수정하지 않는다.
- 초기 FND-01~03에서는 제품 기능을 추가하지 않는다. 고정 upstream의 원본 APK 재현과 증거를 우선한다.

## 변경 경계

- Butterfly `app/`·`api/`, 입력·저장·undo 구조를 보존한다. 생성 코드를 직접 편집하지 않는다.
- 원본 형식·ID·snapshot·migration·lockfile·공유 build wrapper는 통합 담당과 소유권을 맞춘다. 무차별 의존성 업그레이드로 환경 문제를 해결하지 않는다.
- upstream 출처와 라이선스·자산·폰트 고지를 유지한다. 앱/API/자산에 같은 라이선스가 적용된다고 가정하지 않는다.
- 원본 작성자는 활성 태블릿 한 대다. 서버가 `.bfly` 원본을 임의 재작성하지 않으며 전체 원본을 기본 Agent 게시 payload에 넣지 않는다.
- 외부 OCR·AI 전송은 **기본 OFF 정책**이다. 허용 범위 확정 전 실제 필기·외부 provider·유료 API를 연결하지 않는다. 정책 문서를 구현된 보안 제어라고 보고하지 않는다.
- 이 저장소는 public이다. 비밀값·서명키·개인 필기·불필요한 개인정보를 문서·fixture·로그에 넣지 않는다.

## 검증과 보고

- 명령은 `docs/build-baseline.md`의 실제 결과와 검증된 wrapper를 따른다. 미실행 명령은 후보 명령으로 표시한다.
- 기준/결과 SHA, 변경 이유, 정확한 명령·exit code·로그, APK 경로/hash, PASS/FAIL/NOT_RUN/N/A, 후속 의존성을 보고한다.
- 원본 무손실, 같은 revision의 metadata·이미지·텍스트, stable ID, 선택 공개 범위, stale 결과 거부, 재시도 멱등성을 보존한다.
- upstream CI 성공은 자체 빌드 성공이 아니다. 로컬 clone은 Cloud 연결이 아니다. G0는 새 환경 재현까지 필요하다.
- 기기 접근이 없으면 APP-01은 WAITING_DEVICE다. APK 빌드·에뮬레이터·ADB 목록으로 실제 S Pen·한글·복원 시험을 통과시키지 않는다.
- 이전 인계의 Cloud 연결 거절은 당시 세션 기록이다. 현재 사용자가 제공한 managed Cloud 환경에서 FND-03을 재개한다. 환경 사용과 새 환경 publish·새 task 재현 완료를 구분한다.
- 커밋·push·PR·병합 상태를 각각 사실대로 기록한다. 준비된 문서나 로컬 커밋만으로 원격 병합·게이트 통과를 표시하지 않는다.
