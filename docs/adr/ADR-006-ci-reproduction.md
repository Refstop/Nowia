# ADR-006 — GitHub CI를 통한 새 환경 재현

- 날짜: 2026-10-13 KST
- 상태: **채택 — 2026-10-13 KST**. 정상 CI의 설치·분석·테스트·APK 빌드와 별도 실행의 APK artifact 다운로드·크기·SHA-256 대조가 모두 PASS다. FND-04는 VERIFIED, G0는 ACCEPTED로 판정한다. Codex Cloud publish·새 Codex task는 NOT_RUN이며 PR은 미병합이다.

## 맥락과 근거

FND-03은 고정 Butterfly 원본의 APK 빌드를 현재 환경에서 검증했다. FND-04와 G0는 그 결과를 다른 환경에서도 재현할 수 있는지 확인한다. 기존 개발 환경의 재실행이나 upstream release 성공 메타데이터만으로는 이 조건을 충족하지 않는다.

[인계 기준](../agent-handoff.md)은 FND-04에 “연결·publish 및 새 task에서 분석/검사/APK 재현. **대체 CI는 실제 검증 후 ADR**”을 명시한다. G0의 증거는 “고정 upstream 원본 APK + 새 환경 재현”이며, 게이트 `ACCEPTED`와 티켓 `MERGED`는 별개다. 이 ADR은 명시된 대체 CI 경로를 구체화한다.

## 결정

별도 GitHub-hosted Ubuntu 26.04 runner에서 수행한 Nowia 저장소의 설치→분석→기존 테스트→원본 APK 빌드→서명·manifest·소스 보존 검증을 FND-04의 새 환경 재현 경로로 채택한다. 도구와 Flutter/pub/Gradle/Rust 캐시는 새 `RUNNER_TEMP` 경로에 구성하고 기존 개발 환경이나 다른 CI 실행의 캐시를 복원하지 않는다. 해당 실행 안에서 설치·분석이 생성한 캐시는 이후 빌드에서 사용할 수 있다.

정상 CI가 올린 APK를 별도 실행에서 다운로드하고 원래 빌드 증거의 크기·SHA-256과 대조해야 한다. 검증용 실행에서 APK를 다시 빌드하여 다운로드 증거를 대신하지 않는다. 이 조건까지 PASS를 확인했으므로 대체 경로를 채택하고 아래 기술 상태를 적용한다.

| 항목 | 판정 | 판정 범위 |
|---|---|---|
| FND-04 | VERIFIED — ADR-006의 CI 대체 재현 경로 | 고정 소스·도구로 새 GitHub-hosted 환경에서 설치·분석·테스트·APK 재현 |
| G0 | ACCEPTED — 기술 재현 게이트 | FND-03 원본 APK와 별도 환경 재현 및 artifact 검증 확보 |
| Codex Cloud 설정 publish | NOT_RUN | 이 CI 결과는 Codex 환경 게시 실행 증거가 아님 |
| 별도 새 Codex task 실행 | NOT_RUN | GitHub job 실행과 Codex task 실행을 구분 |
| 원격 통합 | PR 검토 상태 / 미병합 | 기술 게이트 통과가 main 병합을 의미하지 않음 |
| APP-01 / G1 | WAITING_DEVICE / NOT_ACCEPTED | Galaxy Tab S7·S Pen·한글·저장·종료 후 복원은 실제 기기에서 별도 검증 |

G1과 제품 기능의 선행 조건은 그대로 유지한다. 이 결정은 Nowia applicationId·제품 기능·외부 OCR/AI 전송·배포 서명 변경을 포함하지 않는다.

## 관찰된 정상 재현 증거

| 항목 | 확인한 값 |
|---|---|
| 저장소 / PR | [Refstop/Nowia PR #1](https://github.com/Refstop/Nowia/pull/1), draft·미병합 |
| 정상 실행 | [38382751680](https://github.com/Refstop/Nowia/actions/runs/38382751680), `pull_request`, SUCCESS |
| 추가 정상 실행 | [38382711491](https://github.com/Refstop/Nowia/actions/runs/38382711491), `push`, SUCCESS; 아래 APK 증거는 PR 실행 기준 |
| PR head | `de79ee491bc95938357689ab3053537f215ef01e` |
| 실제 PR checkout | `6f83f51a65938fe5535ef865ff25fd4141bc3120` — GitHub가 만든 PR merge commit |
| 게시 전 로컬 snapshot | `1b877f181ab1720d4a5eb2590eb7eaeab22b9a42`; PR head와 tree 동일 |
| Butterfly 기준 | `v2.6.0` / `1e4c86b91f4d64361a73598bda0acc587f9381b0` |
| 분석·검사 | quality 12단계 exit 0; API 46개 + 앱 363개 = 409개 테스트 PASS |
| 빌드·검증 | build 26단계 exit 0; 원본 source 보존·APK 서명 PASS, manifest 기록 |
| APK | `app-production-debug.apk`, 219,409,992 bytes |
| APK SHA-256 | `ab5d88c3cc614e152431da8a14fa5f73839f4e2378fdd56073899fd1df47a4de` |

실제 실행 SHA는 PR head와 구분해 기록한다. 출처와 결과는 [게시 기록](../evidence/fnd05-ci/publication.json), [정상 실행 요약](../evidence/fnd05-ci/normal-pr-summary.json), [품질 결과](../evidence/fnd05-ci/normal-pr/quality/result.json), [APK 결과](../evidence/fnd05-ci/normal-pr/apk/result.json), [서명](../evidence/fnd05-ci/normal-pr/apk/apk-signature.log), [manifest](../evidence/fnd05-ci/normal-pr/apk/apk-manifest.log)를 따른다. 전체 판정은 [FND-05 실행 보고서](../evidence/FND-05-ci.md)에 모은다.

FND-05의 실패 감지 조건도 [실패 검증 결과](../evidence/fnd05-ci/failure-probes.json)에 별도로 기록했다. 원본 무결성 오류와 독립 Dart AOT 컴파일 오류가 각각 실제 GitHub job 실패로 전파됐고, 실패 증거 artifact 다운로드와 hash 대조를 통과했다. Dart AOT 검증을 Android APK 컴파일 실패 시험으로 확대 해석하지 않는다.

## 별도 다운로드 검증과 채택 완료

별도 다운로드 검증 브랜치는 `verification/fnd-05-artifact-download`, 게시 SHA는 `b2cce3c8c6d6c37bbb850a1e8888a52b49415a1b`다. [검증 실행 38384463103](https://github.com/Refstop/Nowia/actions/runs/38384463103)은 SUCCESS이며 APK를 다시 빌드하지 않았다. 정상 run `38382751680`의 원본 APK artifact `11804603978` (`nowia-upstream-debug-38382751680-1`)를 다운로드하여 219,409,992 bytes 및 SHA-256 `ab5d88c3cc614e152431da8a14fa5f73839f4e2378fdd56073899fd1df47a4de`의 일치를 확인했다.

[다운로드 검증 결과](../evidence/fnd05-ci/artifact-download/verification.json)의 `source_validation`과 `downloaded_apk_verification`은 모두 PASS다. [검증 실행 기록](../evidence/fnd05-ci/artifact-verification-run.json)의 증거 artifact `11805215417`도 다운로드 후 ZIP SHA-256 `a8538326188c0c3cec271dbd56b6021bb14cc7df1a180737a4c1ee8f041dbaae`를 재확인했다. 이 값은 검증 증거 ZIP의 hash이며 APK hash와 구분한다.

이로써 대체 CI 경로의 실제 재현 및 artifact 확인 조건을 충족했다. [FND-05 실행 보고서](../evidence/FND-05-ci.md)와 [프로젝트 상태](../status.md)에 FND-04 VERIFIED / G0 ACCEPTED의 근거로 이 ADR을 연결한다. Codex Cloud publish·별도 Codex task의 미실행, PR 미병합 및 APP-01/G1 실기기 대기는 유지한다.

## 제약과 재검토 조건

환경별 Android debug key가 달라질 수 있으므로 과거 로컬 APK와 CI APK의 byte 단위 동일성을 요구하지 않는다. 다운로드한 APK는 해당 CI 빌드의 hash와 일치해야 하며, app/API 원본 tree·lockfile·고정 toolchain을 보존해야 한다. runner OS 이미지와 apt 패키지까지 모든 입력을 완전히 고정한 비트 재현 빌드라는 주장은 하지 않는다.

필수 단계 실패·timeout, 원본/lock 변경, artifact 누락 또는 hash 불일치, 기존 개발 캐시에 의존한 실행이 발견되면 FND-04/G0 통과 근거를 재검토한다. 물리 기기의 입력·저장 결함은 APP-01/G1에서 별도로 판정한다.
