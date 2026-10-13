# Nowia — Note with Agent

Android 태블릿의 자유 캔버스 필기와 외부 Agent 읽기 연동을 준비하는 Butterfly thin fork입니다.

새 컨테이너와 GitHub CI에서 도구 설치, 분석, 409개 테스트, 원본 debug APK 빌드·서명 검증을 완료했습니다. CI가 만든 APK는 별도 job에서 다운로드해 SHA-256 일치도 확인했습니다. 앱/API 코드는 Butterfly v2.6.0에서 변경하지 않았습니다. [ADR-006](docs/adr/ADR-006-ci-reproduction.md)에 따라 새 환경 재현 게이트 G0를 통과했고, [초안 PR #1](https://github.com/Refstop/Nowia/pull/1)은 미병합 상태입니다. 다음은 실기기 시험입니다. [현재 상태](docs/status.md)와 [CI 검증 증거](docs/evidence/FND-05-ci.md)를 확인하세요.

- 대상: Galaxy Tab S7 / S Pen / Android 13
- 외부 OCR·AI로 필기 전송: 기본 OFF 정책. 관련 Nowia 기능은 아직 구현되지 않았습니다.
- 원본: [Butterfly](https://github.com/LinwoodDev/Butterfly), commit `1e4c86b91f4d64361a73598bda0acc587f9381b0`
- [입력과 결정](docs/project-inputs.md) · [후속 배정](docs/agent-handoff.md) · [기기 시험](docs/runbooks/device-baseline.md)
- [upstream 조사](docs/upstream-audit.md) · [기준선 ADR](docs/adr/ADR-001-butterfly-baseline.md)

앱 기본 라이선스는 [AGPL-3.0](LICENSE), API는 [Apache-2.0](api/LICENSE)입니다. `app/images/`와 upstream 문서에는 [CC-BY-SA-4.0](BRANDING_LICENSE)이 적용됩니다. 범위와 폰트 고지는 [upstream 원문 README](docs/foundation/butterfly-readme-v2.6.0.md) 및 각 라이선스를 보존합니다. Nowia는 공식 Butterfly 배포판이 아닙니다.
