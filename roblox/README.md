# 저금통 부수기 — 로블록스판

웹판(`../src`)과 같은 게임을 로블록스로 옮긴 것. 밸런스·전투·강화 수치는 웹판과 똑같다.

- 내 캐릭터가 망치를 들고 마당을 돌아다니며, 돌아다니는 저금통을 **클릭(폰은 화면 터치)** 으로 내려친다. 가까운 저금통 쪽으로 자동으로 몸을 돌린다.
- 범위 공격을 강화해 망치가 커지면 **캐릭터도 같은 배율로 함께 커진다**(최대 2배).
- 제한 시간 안에 스테이지의 저금통을 다 깨면 클리어. 실패해도 동전은 남는다.
- 결과 화면 → "강화하러 가기"에서 파워·연타 속도·범위 공격·크리티컬·연쇄 번개를 강화한다.
- 진행(스테이지·동전·스킬·음소거)은 로블록스 DataStore에 저장된다.

## 실행하기

**바로 해 보기**: 저장소를 받은 뒤(`git pull`) 이 폴더의 `PiggySmash.rbxl` 을 Roblox Studio로 열고 ▶ Play. Rojo 없이도 된다.
코드를 고친 뒤에는 아래 2번처럼 다시 빌드해서 이 파일을 새로 만든다.

1. [Rojo](https://rojo.space) 를 설치한다. `rokit install` 이면 rojo·lune·selene이 한 번에 깔린다.
2. 이 폴더에서 `rojo build -o PiggySmash.rbxl` → 만들어진 파일을 Roblox Studio로 열고 ▶ Play.
   - 고치면서 하려면 `rojo serve` 를 켜고 Studio의 Rojo 플러그인에서 Connect.
3. Studio에서 저장까지 확인하려면: 게임을 한 번 Publish 한 뒤 **Game Settings → Security → Enable Studio Access to API Services** 를 켠다.
   꺼져 있으면 경고만 뜨고 그 접속에서는 저장하지 않는다(게임은 그대로 된다).

## 구조

| 위치 | 들어가는 곳 | 내용 |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | 규칙(웹판 `src/logic` 이식): `Balance`(난이도·경제), `Upgrades`(스킬), `Combat`(타격 판정), `StageRun`(한 판 진행), `SaveData`, `RunCheck`(서버 결과 검증), `Config`(월드 크기·색·효과음) |
| `src/shared/HammerTool` | ReplicatedStorage.Shared | 캐릭터가 손에 드는 망치 도구 |
| `src/server` | ServerScriptService | 저장(`SaveStore`), 마당(`Arena`), 캐릭터 크기·망치 쥐여 주기(`Character`), 원격 호출 처리(`Main`) |
| `src/client` | StarterPlayerScripts | 화면 흔들림(`CameraRig`), 저금통·휘두르는 망치 모양(`Art`), 타격 연출(`Effects`), 화면(`Ui`), 한 판(`Play`), 흐름(`Main`) |

- 판은 **각자 화면에서만** 돈다. 같은 서버의 다른 사람은 내 캐릭터와 망치는 보지만 내 저금통은 못 본다(혼자 하는 게임이라).
- 걸어가서 때리는 만큼 제한 시간은 웹판의 1.5배다(`Balance.luau` 의 `TIME_SCALE`).
- 서버는 판 시작~끝 시간을 직접 재서, 그 시간 안에 나올 수 있었던 저금통 수·금 저금통 수를 넘는 보고는 깎는다(`RunCheck`).
- 강화 구매도 서버에서 확인한다. 판이 진행 중일 때는 강화할 수 없다.
- 효과음은 로블록스 기본 소리를 쓴다. `src/shared/Config.luau` 의 `SOUNDS` 를 크리에이터 스토어 소리(`rbxassetid://...`)로 바꾸면 손맛이 더 좋아진다.
- 밸런스 조정은 웹판처럼 `Balance.luau`, `Upgrades.luau` 상수만 바꾼다.

## 테스트

```sh
lune run tests/run
```

`src/shared` 의 규칙을 로블록스 없이 검사한다(웹판 vitest 테스트를 옮긴 것 + 서버 검증 테스트).
