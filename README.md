# Nowia — Note with Agent

Android 태블릿의 자유 캔버스 필기와 외부 Agent 읽기 연동을 준비하는 Butterfly thin fork입니다.

기존 개발 캐시를 가져오지 않은 새 컨테이너에서 도구 설치, 분석, 409개 테스트, 원본 debug APK 빌드·서명 검증을 완료했습니다. 앱/API 코드는 Butterfly v2.6.0에서 변경하지 않았습니다. GitHub 쓰기 접근을 확인해 원격 CI 검증을 진행 중이며, 별도 Codex task와 실기기 검증도 남아 있습니다. [현재 상태](docs/status.md)와 [재현 증거](docs/evidence/FND-04-05.md)를 확인하세요.

- 대상: Galaxy Tab S7 / S Pen / Android 13
- 외부 OCR·AI로 필기 전송: 기본 OFF 정책. 관련 Nowia 기능은 아직 구현되지 않았습니다.
- 원본: [Butterfly](https://github.com/LinwoodDev/Butterfly), commit `1e4c86b91f4d64361a73598bda0acc587f9381b0`
- [입력과 결정](docs/project-inputs.md) · [후속 배정](docs/agent-handoff.md) · [기기 시험](docs/runbooks/device-baseline.md)
- [upstream 조사](docs/upstream-audit.md) · [기준선 ADR](docs/adr/ADR-001-butterfly-baseline.md)

앱 기본 라이선스는 [AGPL-3.0](LICENSE), API는 [Apache-2.0](api/LICENSE)입니다. `app/images/`와 upstream 문서에는 [CC-BY-SA-4.0](BRANDING_LICENSE)이 적용됩니다. 범위와 폰트 고지는 [upstream 원문 README](docs/foundation/butterfly-readme-v2.6.0.md) 및 각 라이선스를 보존합니다. Nowia는 공식 Butterfly 배포판이 아닙니다.
