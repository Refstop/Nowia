# Nowia — 현재 상태

기록: 2026-10-13 KST. **원본 APK의 로컬·새 컨테이너·GitHub CI 재현과 CI artifact 별도 다운로드 검증을 완료했다.** 엄격한 분석과 409개 테스트를 통과했다. 제품 기능은 추가하지 않았다.

| 항목 | 상태 | 확인한 범위 / 남은 조건 |
|---|---|---|
| FND-01 | VERIFIED | 인계 65개 파일 무결성 PASS, 입력 기록 복원 |
| FND-02 | VERIFIED / PR 미병합 | 고정 upstream app/api 원본 tree·bytes 일치, 원격 작업 브랜치에 동일 tree 게시 |
| FND-03 | VERIFIED / PR 미병합 | 최초 빌드·재실행, APK hash·서명·manifest·원본 보존 PASS |
| FND-04 | VERIFIED — ADR-006 | 새 컨테이너 및 GitHub-hosted runner의 빈 도구·캐시에서 설치→분석→테스트→APK 재현. Codex 설정 publish·별도 Codex task는 NOT_RUN |
| FND-05 | VERIFIED / PR 미병합 | 정상 push/PR CI SUCCESS, 두 의도한 실패 job 확인, 증거 ZIP 다운로드·hash 대조 및 별도 job의 APK 다운로드·hash 대조 PASS |
| APP-01 | WAITING_DEVICE | 15~20분 시험 안내·결과 양식 준비. Galaxy Tab S7/S Pen/한글/저장·복원 시험 미실행 |
| G0 | ACCEPTED | [ADR-006](adr/ADR-006-ci-reproduction.md)의 실제 검증된 대체 CI 경로로 기술 재현 충족 |
| G1 | NOT_ACCEPTED | 실기기 적합성 미검증 |

원격 브랜치는 `task/fnd-04-05-ci`, [초안 PR #1](https://github.com/Refstop/Nowia/pull/1)은 미병합이다. 정상 CI가 검증한 head는 `de79ee491bc95938357689ab3053537f215ef01e`, 실제 PR checkout은 `6f83f51a65938fe5535ef865ff25fd4141bc3120`이다. 이 둘과 게시 전 로컬 snapshot `1b877f181ab1720d4a5eb2590eb7eaeab22b9a42`의 tree는 `5f6c46411d3afdd359c10081686f448700e1c3f9`로 동일하다. 후속 문서·증거 정리 commit은 빌드 실행 SHA와 구분한다. upstream은 `1e4c86b91f4d64361a73598bda0acc587f9381b0`다.

| APK | 위치 / 출처 | SHA-256 |
|---|---|---|
| 기존 기기 시험 안내 기준 | `build/artifacts/butterfly-v2.6.0-production-debug.apk` | `da100dbcde47a4b8d03c3ef1e0cbce869146a5ca2beaf929babf2bedf1263c5b` |
| 새 컨테이너 재현 결과 | `/workspace/fnd04-repro/artifacts/butterfly-v2.6.0-production-debug.apk` | `e05e1dab8afa56cb99ec539b6fa8a83203b71dbe9f330fae0cc151cb0f2f50d9` |
| 정상 PR CI 결과 | [run 38382751680](https://github.com/Refstop/Nowia/actions/runs/38382751680), artifact `11804603978` | `ab5d88c3cc614e152431da8a14fa5f73839f4e2378fdd56073899fd1df47a4de` |

모두 `dev.linwood.butterfly`, `2.6.0+199`이며 debug 서명키가 서로 다르다. CI APK는 219,409,992 bytes다. 다른 서명의 APK를 기존 앱에 업데이트 설치할 수 있다고 가정하지 않는다. 기존 앱·노트를 삭제해서 시험하지 않는다. CI artifact는 14일 보관되며 위 APK의 현재 만료 예정은 2026-10-27 19:34:35 KST다. 증거 JSON·로그는 저장소에 보존한다.

학교 계정 Refstop의 GitHub 설치 접근 수정 후 소스 게시·PR·CI가 성공했다. ChatGPT 재연결은 필요하지 않았다. 이전 403은 [과거 보고서](evidence/FND-04-05.md), 최종 판정은 [FND-05 실행 보고서](evidence/FND-05-ci.md)를 따른다. main 병합은 없다.

다음 사용자 확인은 [태블릿 시험](runbooks/device-baseline.md)이다. [결과 양식](runbooks/device-results-template.md)에 펜·한글·저장·종료 후 복원을 기록한다. PR 검토와 기기 게이트는 별개다. 외부 OCR·AI OFF는 정책이며 관련 Nowia 기능은 아직 구현하지 않았다.
