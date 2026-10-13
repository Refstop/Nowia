# FND-02 증거

판정: 로컬 snapshot 및 원본 보존 검증 완료 / 원격 전달 BLOCKED.

- upstream URL: https://github.com/LinwoodDev/Butterfly
- tag object: `68cb06f1aeb6562977ed0a796eed2fba12cb7448`
- source commit: `1e4c86b91f4d64361a73598bda0acc587f9381b0`
- local import commit: `aad94d6f5d5de8f984ca90e3665895feeb092779`
- 최초 Nowia parent: `b0ab030fa132028fee02b3e4210257d894dc5e00`

공식 repo tag와 commit을 조회하고 실제 소스를 clone했다. local shallow clone에서 tag를 Nowia로 fetch하는 명령은 `Could not read ... / revision walk setup failed`(exit 1)로 실패하여 전체 upstream history 병합을 하지 않고 파일 snapshot import로 전환했다.

`python3 tools/nowia/verify_baseline.py` exit 0:

```text
PASS app unchanged tree ff163eaaab6fbf214b87f76c1edb133cc9edd4d6
PASS api unchanged tree 3d0f3e16e0f55ad4c593568dae8262f3ffbad55d
```

독립 검토에서도 앱/API tracked bytes, root/API/branding/font 라이선스 및 보존한 upstream README의 byte 일치를 확인했다. 최종 비교는 원본 4,332 파일 중 README 변경, 7개 workflow 내용 그대로 보존·위치 이동만 허용한다. 제품 앱/API 수정은 없다.

환경/문서 변경: Nowia README, AGENTS, 결정/티켓/실기기 지시서, pins·빌드 wrapper, 제한된 debug CI 후보. 원본 배포/자동 수정 workflow는 비활성 보관한다. 원격 CI가 실행되었다는 뜻은 아니다.

완료에 남은 항목: 권한 있는 환경에서 원격 작업 브랜치 push, PR diff 검토와 통합. 라이선스 전체 전이 의존성 검토와 실제 배포 방식 판단도 미완료다.
