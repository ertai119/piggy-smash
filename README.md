# 저금통 부수기

망치로 저금통을 부수고 동전으로 망치를 강화하는 모바일 웹 게임.

- **폰에 설치**: 안드로이드 크롬에서 게임 주소를 열고 메뉴 → "홈 화면에 추가". 한 번 설치하면 오프라인에서도 실행된다.
- **개발**: `npm install` 후 `npm run dev` (같은 와이파이의 폰에서 표시된 Network 주소로 접속 가능), 테스트는 `npm test`.
- **배포**: `main`에 푸시하면 GitHub Actions가 테스트·빌드 후 GitHub Pages에 올린다. 밸런스 수치는 `src/logic/balance.ts`, `src/logic/upgrades.ts`.

## 로블록스판

`roblox/` 폴더에 같은 게임의 로블록스 버전이 있다. 실행 방법은 [`roblox/README.md`](roblox/README.md).
