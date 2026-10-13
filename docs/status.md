# Nowia — 현재 상태

기록: 2026-10-13 KST. 범위: FND-04·05 후속 작업. **기존 개발 캐시를 가져오지 않은 새 컨테이너에서 설치→분석→409개 테스트→Butterfly 원본 APK 재현 성공.** 제품 기능은 추가하지 않았다.

| 항목 | 상태 | 확인한 범위 / 남은 조건 |
|---|---|---|
| FND-01 | VERIFIED (문서) | 인계 65개 파일 무결성 PASS, 입력 기록 복원 |
| FND-02 | VERIFIED (로컬) / 원격 미반영 | 고정 upstream app/api 원본 tree·bytes 일치 |
| FND-03 | VERIFIED (미병합) | 최초 빌드·재실행과 APK hash·서명·manifest·원본 보존 PASS |
| FND-04 Cloud | REVIEW / 컨테이너 재현 PASS | 빈 도구·캐시에서 전체 성공. Cloud 설정 publish·별도 Codex task는 NOT_RUN |
| FND-05 CI | IN_PROGRESS | Refstop 쓰기 재검증·작업 브랜치 생성 성공. 소스 전송 및 실제 GitHub job·artifact 검증 진행 |
| APP-01 | WAITING_DEVICE | 15~20분 시험 안내·결과 양식 준비. Galaxy Tab S7/S Pen/한글/저장·복원 시험 미실행 |
| G0 | NOT_ACCEPTED | 새 컨테이너 재현 증거 확보. 기존 publish·새 task 조건은 미충족 |
| G1 | NOT_ACCEPTED | 실기기 적합성 미검증 |

현재 브랜치: `task/fnd-04-05-ci`. 실행한 구현 commit은 `c46c32f66534db09a144ce31000fd502282dd00a`다. 뒤따르는 문서·증거 commit과 실제 빌드 SHA를 구분한다. 원본 복원/인계/최초 검증 이력은 `355ca54` → `d1feecc` → `79fb88c`이며 upstream은 `1e4c86b91f4d64361a73598bda0acc587f9381b0`다.

| APK | 경로 | SHA-256 |
|---|---|---|
| 기존 기기 시험 안내 기준 | `build/artifacts/butterfly-v2.6.0-production-debug.apk` | `da100dbcde47a4b8d03c3ef1e0cbce869146a5ca2beaf929babf2bedf1263c5b` |
| 새 컨테이너 재현 결과 | `/workspace/fnd04-repro/artifacts/butterfly-v2.6.0-production-debug.apk` | `e05e1dab8afa56cb99ec539b6fa8a83203b71dbe9f330fae0cc151cb0f2f50d9` |

두 APK 모두 `dev.linwood.butterfly`, `2.6.0+199`이며 debug 서명키가 서로 다르다. 새 APK는 219,408,832 bytes다. 다른 서명의 APK를 기존 앱에 업데이트 설치할 수 있다고 가정하지 않는다. 기존 앱·노트를 삭제해서 시험하지 않는다.

학교 계정 Refstop의 GitHub 설치 접근을 사용자가 수정한 뒤 브랜치 생성을 재시도해 성공했다. ChatGPT 재연결은 하지 않았다. `task/fnd-04-05-ci` 원격 브랜치가 있으며 소스 반영·CI 검증을 진행한다. 이전 403은 [과거 실행 보고서](evidence/FND-04-05.md), 현재 접근 성공은 [재검증 기록](evidence/fnd05-ci/access-restored.json)을 따른다. main 병합은 없다.

다음 작업: [CI 실제 실행](runbooks/ci-baseline.md), 별도 환경 publish·새 task 재현, 준비되는 시점의 [태블릿 시험](runbooks/device-baseline.md). 외부 OCR·AI OFF는 정책이며 관련 Nowia 기능은 아직 구현하지 않았다.
