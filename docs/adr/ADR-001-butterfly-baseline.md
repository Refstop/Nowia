# ADR-001 — Butterfly 기준선과 thin fork 경계

- 날짜: 2026-10-13 KST
- 상태: 소스 기준선 채택. 제품 기반 적합성 승인은 G0/G1 이후.

## 맥락

Nowia는 자유 캔버스·단일 활성 태블릿 작성자·선택 영역 게시·외부 MCP 읽기 연동을 지향한다. 최초 범위는 FND-01~03이며, 기능 변경 전 원본 APK 재현이 필요하다.

## 결정

Butterfly `v2.6.0`의 peeled commit `1e4c86b91f4d64361a73598bda0acc587f9381b0`를 고정한다. annotated tag object는 `68cb06f1aeb6562977ed0a796eed2fba12cb7448`이다. 최신 버전이라는 주장은 하지 않는다.

Nowia 초기 `main`의 `b0ab030fa132028fee02b3e4210257d894dc5e00`을 부모로 원본 파일 snapshot을 로컬 import했다. import commit은 `aad94d6f5d5de8f984ca90e3665895feeb092779`이다. import 시 root README는 초기 Nowia 내용을 유지했고 별도 사본도 보존했다. 앱/API·나머지 원본 파일은 동일하다. GitHub의 공식 fork 관계는 없으며 upstream 전체 commit history를 병합한 것도 아니다. 원본 provenance와 Git tree를 명시적으로 보존한다. 원격 push는 인증 부재, 연결 API 쓰기는 403으로 실패하여 로컬 결과만 존재한다.

`app/`와 `api/`의 tracked tree/bytes를 변경하지 않는다. 앱 이름·applicationId·서명·필기 엔진·문서 형식·생성 코드·lockfile 변경은 baseline 이후 별도 티켓이다.

## 대안

- 최신 브랜치 추적: 움직이는 소스로 인해 재현성이 낮아 보류.
- 앱 재작성: 원본 펜·저장 동작을 잃으므로 채택하지 않음.
- upstream history 병합: 로컬 shallow checkout에서 fetch가 exit 1로 실패했다. 원본 snapshot import로 전환했으며 전체 history 보존을 주장하지 않는다. 후속 upstream 업데이트는 고정 SHA 간 diff를 검토한다.

## 비용과 제약

기존 Nowia README는 `docs/foundation/nowia-initial-readme.md`, Butterfly README는 같은 디렉터리의 별도 파일로 보존했다. 초기 upstream 배포·이미지 수정·다중 플랫폼 workflow 7개는 내용 변경 없이 `docs/upstream-workflows/*.disabled`로 이동했다. FND-03용 Android debug 진단 workflow만 활성화한다. 이는 환경/운영 변경이며 앱 코드 변경과 분리한다.

라이선스 고지를 제거하지 않는다. AGPL 앱, Apache API, CC-BY-SA 지정 자산·문서 및 폰트 라이선스 목록은 `docs/upstream-audit.md`를 따른다. 모든 전이 의존성의 배포 검토는 아직 완료되지 않았다.

## 검증

`python3 tools/nowia/verify_baseline.py`는 원본 app/api tree hash, tracked diff, untracked source를 검사한다. 빌드/기기 실행 증거는 별도 문서에서 판정한다. upstream CI 성공은 자체 빌드 성공이 아니다.

## 재검토 조건

고정 toolchain으로 재현 불가, Galaxy Tab S7 필기 부적합, 원본 저장 유실 또는 확장 정보 보존 불가 시 원인과 최소 수정 spike 결과를 먼저 검토한다. 무작위 dependency upgrade나 플랫폼 전환을 하지 않는다.
