# FND-01 증거

날짜: 2026-10-13 KST. 판정: 입력 조사 VERIFIED, 원격 반영은 별도 BLOCKED.

| 실행/관찰 | 결과 |
|---|---|
| `GET /repos/Refstop/Nowia` (연결 GitHub) | public, fork=false, main, permissions.push=true |
| `GET /repos/Refstop/Nowia/contents` | README.md 7 bytes만 존재 |
| `git clone https://github.com/Refstop/Nowia.git Nowia` | exit 0 |
| `git status --short` | 초기 출력 없음, 사용자 미커밋 변경 없음 |
| `git log -1 --format=fuller` | `b0ab030fa132028fee02b3e4210257d894dc5e00`, Initial commit |
| `git remote -v` | origin=https://github.com/Refstop/Nowia.git |
| AGENTS.md 조사 | 최초 없음. 이번 로컬 작업에 새로 작성 |

D01~D09는 `docs/project-inputs.md`에 기록했다. 기기 사양은 사용자 제공값이며 실측값이 아니다. 원격 metadata의 push=true는 현재 토큰으로 실제 쓰기가 된다는 뜻이 아니었다.

원격 실행 시도:

```text
git push -u origin task/fnd-01-03-bootstrap
exit 128
fatal: could not read Username for 'https://github.com': No such device or address
```

연결 GitHub `create_tree` 호출도 HTTP 403, `Resource not accessible by integration`으로 실패했다. 정확한 GitHub App/토큰 권한 원인은 확인하지 못했다. 쓰기 성공·PR 생성·병합을 주장하지 않는다.

Codex Cloud 화면 접근은 브라우저 권한 거절로 중단했다. 이는 과거 Cloud 오류의 원인 분석이 아니다. 현 세션에서 환경 생성·publish·새 task 실행은 하지 않았다.
