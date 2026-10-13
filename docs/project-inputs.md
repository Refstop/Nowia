# Nowia 프로젝트 입력

확인 기준일: 2026-10-13 KST. 제품명은 **Nowia — Note with Agent**다. 아래의 정책 결정과 실제 구현·검증 상태를 구분한다. 최신 티켓 상태는 [status.md](status.md), 빌드 결과는 [build-baseline.md](build-baseline.md)를 따른다.

## 확정된 입력과 기준선

| 항목 | 확인된 값 | 근거·한계 |
|---|---|---|
| 저장소 | [Refstop/Nowia](https://github.com/Refstop/Nowia), public, 기본 브랜치 `main` | GitHub 조회. 쓰기·PR·병합 결과는 별도 실행 증거 필요 |
| 최초 원격 기준 | `b0ab030fa132028fee02b3e4210257d894dc5e00` | 초기 README만 존재. 초기 `AGENTS.md` 없음 |
| 작업 브랜치 | `task/fnd-04-05-ci` (로컬) | FND-03 복원 후 독립 재현·CI 구현. 실행 commit `c46c32f`; 학교 계정 Refstop 접근 수정 후 원격 브랜치 생성 성공, CI 진행 |
| 소스 import commit | 원 인계 `aad94d6f5d5de8f984ca90e3665895feeb092779`; 이번 복원 `355ca54` | 동일 import tree와 app/api 원본을 확인. 복원 인계 HEAD는 `d1feecc5beecc21bb30901135f6d9eca04b9c94c`; 원격 통합은 미실행 |
| Butterfly 기준 | `v2.6.0` → `1e4c86b91f4d64361a73598bda0acc587f9381b0` | 조사한 기준 버전이며 최신 버전이라는 주장은 하지 않음 |
| 앱 이름 | Nowia / Note with Agent | 사용자 확정. baseline APK의 표시 이름·applicationId를 변경했다는 의미는 아님 |
| 목표 기기 | Galaxy Tab S7 / S Pen / Android 13 | 사용자 제공. 물리적 기기 연결·ADB·USB 접근·설치·펜 입력 시험은 미실행 |
| 개발 데이터 | 합성 노트·공개 가능한 fixture | 실제 개인 노트는 baseline/CI 시험에 사용하지 않음 |
| 외부 OCR·AI 전송 | **기본 OFF** | 허용 범위 미정 시 OFF로 진행한다는 지시. 전송 차단 설정·코드를 구현/검증했다는 의미는 아님 |

## D01~D09 결정 목록

| ID | 결정 상태 | 남은 입력·작업 | 미확정 상태에서 가능한 일 |
|---|---|---|---|
| D01 저장소 | 확인됨 / 쓰기 재검증 성공 | 사용자 선택 계정 Refstop. 설치 접근 수정 후 원격 브랜치 생성 성공 | FND-05 실제 CI 진행 |
| D02 기기 | 사양 확정 / 시험 대기 | 모델 코드, OS build, 주사율, 실제 접근, 설치·필기 관찰 | 빌드·fixture·시험 패키지 준비 |
| D03 MCP client | UNRESOLVED | 첫 client, 사용 위치, transport·이미지·인증 지원 | 계약 초안·합성 fixture |
| D04 서버 | UNRESOLVED | 호스트, OS/CPU/RAM/디스크/GPU, 접속 방식 | fake recognizer 설계 |
| D05 외부 전송 | 기본 OFF / 허용 범위 UNRESOLVED | 허용 자료·제외 노트·provider·전송 범위 | 외부 전송 없는 로컬/fake 경로 |
| D06 예산 | UNRESOLVED | 월 API 상한, 게시 저장량, 재시도 상한 | 비용 없는 fake 경로 |
| D07 앱 식별·서명 | 이름만 확정 | Nowia applicationId, signing 담당, 채널, 기존 앱 공존 | upstream 식별자를 유지한 원본 빌드. 설치 충돌은 별도 확인 |
| D08 백업 | UNRESOLVED | 목적지·보관 기간·복원 정책 | 합성 데이터 복원 설계 |
| D09 과거 Cloud 오류 | UNRESOLVED | 실패 명령·발생 단계·원본 로그 | 현재 환경의 실패를 독립 진단 |

## 기본 설계와 실제 환경 상태

- 기본 설계는 Butterfly thin fork, 자유 캔버스, 단일 활성 태블릿 작성자, 선택 영역 게시, 첫 MVP의 외부 Agent 읽기 전용이다. 제품 구현 완료를 뜻하지 않는다.
- 현재 사용자가 제공한 managed Cloud 작업 공간에서 FND-03을 재개했다. 이전 인계의 Cloud 브라우저 연결 거절은 당시 기록이다. 현재 환경 사용이 별도의 환경 publish·후속 새 task 재현 완료를 의미하지 않는다.
- GitHub 소스 접근, 로컬 개발 환경, Codex Cloud 환경 연결은 서로 다른 상태다. 하나의 성공을 다른 항목의 성공으로 기록하지 않는다.
- APP-01은 `WAITING_DEVICE`다. 실기기 시험 전 G1을 통과시키지 않는다.
- public 저장소의 로그·fixture에는 토큰·서명키·개인 필기·불필요한 사용자 정보를 넣지 않는다.
