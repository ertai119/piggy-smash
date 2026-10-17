# 망치로 저금통 부수기 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 갤럭시 Z 폴드8 크롬에서 홈 화면에 설치해 오프라인으로 즐기는, 저금통을 망치로 부수고 동전으로 망치를 강화하는 끝없는 스테이지형 웹 게임을 만든다.

**Architecture:** 게임 규칙(난이도, 강화, 타격 판정, 스테이지 진행, 저장, 화면 배치)은 Phaser에 의존하지 않는 순수 TypeScript 모듈(`src/logic/`)로 만들고 Vitest로 테스트한다. Phaser 씬(`src/scenes/`)은 이 모듈을 호출해 그리고 입력을 전달하는 얇은 층이다. 그림은 코드로 그려 텍스처로 만들고, 효과음은 Web Audio로 합성한다. vite-plugin-pwa로 오프라인 설치를 지원하고 GitHub Actions로 GitHub Pages에 배포한다.

**Tech Stack:** TypeScript 5.9, Vite 8, Phaser 4.2.1, Vitest 5, vite-plugin-pwa 2, @vite-pwa/assets-generator 2, GitHub Pages + Actions.

**Spec:** `docs/superpowers/specs/2026-10-17-piggy-smash-design.md` (시안: `docs/superpowers/specs/mockups/`)

## Global Constraints

- 대상: 갤럭시 Z 폴드8 크롬. **접은 화면과 펼친 화면 모두** 플레이 가능, 게임 중 접고 펼쳐도 새 크기에 맞춤. 기본 세로 모드.
- 그림체: 시안 C "선명한 캐주얼" — 굵은 검은 테두리(2.5~3 단위), 진한 색, 파란 방사형 그라데이션 배경(`#4fc3f7` → `#1565c0`). 일반 저금통 `#ff4f8b`/코 `#ff80ab`, 금 저금통 `#ffd54f`/코 `#ffe082`, 동전 `#ffca28`, HUD 박스 `#0d1b3e`, 체력 바 `#76ff03`(30% 이하 `#ff7043`), 충격 별 `#fff59d`.
- 모든 화면 문구는 한국어.
- 서버·백엔드 없음. 저장은 `localStorage` 키 `piggy-smash.save.v1`.
- 실패 조건(스펙): 타격감이 약하거나 저금통이 적으면 실패. 첫 스테이지부터 화면에 8마리가 돌아다닌다.
- 손가락을 대고 있어도 자동 연타 없음 — 터치(pointerdown)마다 한 번.
- 강화는 스테이지 사이 강화 화면에서만.
- 수치는 전부 `src/logic/balance.ts`와 `src/logic/upgrades.ts`의 상수에 모은다.
- 정적 배포를 위해 Vite `base: './'`.
- 외부로 나가는 작업(GitHub 저장소 생성, 푸시, Pages 설정)은 실행 직전에 사용자에게 확인받는다.

## Review Focus

1. **게임 중 폰을 접거나 펼침** → 저금통이 새 경기장 밖으로 나가지 않고, HUD가 다시 배치되고, 타이머·진행이 유지된다. 테스트: Task 7 `clampToArena`, Task 9 확인 단계.
2. **플레이 중 앱을 벗어났다 돌아옴** → 그동안 시간이 흐르지 않는다. 돌아온 첫 프레임의 큰 delta로 타이머가 뭉텅이로 줄지 않는다. 테스트: Task 6 `clamps large frame delta`, Task 9 visibility 일시정지.
3. **아주 높은 스테이지** → 체력·비용·동전이 `NaN`/`Infinity` 없이 유한하고, 화면 숫자는 축약 표기된다. 테스트: Task 1 `formatNumber`, Task 2 `stays finite up to stage 300`.
4. **저장 데이터가 깨졌거나 저장소 접근이 막힘** → 크래시 없이 기본값으로 시작한다. 테스트: Task 4.
5. **두 손가락 동시 터치·간격보다 빠른 연타** → 최소 간격 안의 터치는 무시되고 쌓이지 않는다. 테스트: Task 5 `SwingGate`.

---

## File Structure

```
piggy-smash/
├── index.html                 # 캔버스 컨테이너, 뷰포트 메타
├── package.json / tsconfig.json / vite.config.ts / pwa-assets.config.ts
├── public/icon.svg            # 앱 아이콘 원본(저금통)
├── .github/workflows/deploy.yml
├── src/
│   ├── main.ts                # Phaser.Game 생성, 씬 등록
│   ├── logic/                 # 순수 TS, Phaser 의존 금지
│   │   ├── format.ts          # 숫자 표기
│   │   ├── balance.ts         # 스테이지 난이도·경제 곡선
│   │   ├── upgrades.ts        # 스킬 정의, 비용, 망치 능력치
│   │   ├── save.ts            # 저장/불러오기
│   │   ├── combat.ts          # 터치 판정, 범위·크리·번개, 연타 간격
│   │   ├── stageRun.ts        # 한 판 상태(생성, 타이머, 콤보, 승패)
│   │   └── layout.ts          # 화면 크기 → HUD/경기장/단위 크기
│   ├── art/textures.ts        # 코드로 텍스처 그리기
│   ├── fx/sound.ts            # Web Audio 합성 효과음
│   ├── fx/haptics.ts          # 진동
│   ├── fx/effects.ts          # 타격·파괴·동전·번개·흔들림 연출
│   ├── game/state.ts          # 현재 SaveData 보관 + 저장 호출(씬 공용)
│   └── scenes/
│       ├── BootScene.ts       # 텍스처 생성 후 Title로
│       ├── TitleScene.ts
│       ├── PlayScene.ts
│       ├── ResultScene.ts
│       └── UpgradeScene.ts
└── tests/logic/*.test.ts
```

---

### Task 1: 프로젝트 뼈대와 숫자 표기

**Files:**
- Create: `package.json`, `tsconfig.json`, `vite.config.ts`, `index.html`, `src/main.ts`, `src/logic/format.ts`
- Test: `tests/logic/format.test.ts`

**Interfaces:**
- Produces: `formatNumber(n: number): string`, npm 스크립트 `dev`, `build`, `test`(= `vitest run`), `typecheck`(= `tsc --noEmit`)

- [ ] **Step 1: 의존성 설치**

```bash
npm init -y
npm i phaser@4.2.1
npm i -D typescript@5.9.3 vite@8 vitest@5 vite-plugin-pwa@2 @vite-pwa/assets-generator@2
```

`package.json`에 `"type": "module"`과 위 스크립트 4개를 넣는다. `tsconfig.json`: `strict: true`, `target/module: ES2022`, `moduleResolution: bundler`, `include: ["src", "tests"]`. `vite.config.ts`: `base: './'`, `test.include: ['tests/**/*.test.ts']`.

- [ ] **Step 2: 실패하는 테스트 작성** — `tests/logic/format.test.ts`

```ts
import { describe, it, expect } from 'vitest';
import { formatNumber } from '../../src/logic/format';

describe('formatNumber', () => {
  it('uses commas below 10,000', () => {
    expect(formatNumber(0)).toBe('0');
    expect(formatNumber(1240)).toBe('1,240');
    expect(formatNumber(9999)).toBe('9,999');
  });
  it('abbreviates large numbers with one decimal', () => {
    expect(formatNumber(12_345)).toBe('12.3K');
    expect(formatNumber(4_560_000)).toBe('4.6M');
    expect(formatNumber(7_800_000_000)).toBe('7.8B');
    expect(formatNumber(2.5e12)).toBe('2.5T');
  });
  it('falls back to exponent beyond trillions and never prints NaN', () => {
    expect(formatNumber(3.2e16)).toBe('3.2e16');
    expect(formatNumber(Infinity)).toBe('∞');
    expect(formatNumber(NaN)).toBe('0');
  });
  it('floors fractions', () => {
    expect(formatNumber(12.9)).toBe('12');
  });
});
```

- [ ] **Step 3: 실패 확인** — Run: `npm test` / Expected: FAIL, `format` 모듈 없음

- [ ] **Step 4: `formatNumber` 구현** — `src/logic/format.ts`. 1e15 이상은 `n.toExponential(1).replace('+', '')`(=`3.2e16`).

- [ ] **Step 5: 통과 확인** — Run: `npm test` / Expected: 4 passed

- [ ] **Step 6: 빈 게임이 뜨는지 확인**

`index.html`: `<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">`, `body{margin:0;background:#1565c0;overflow:hidden;touch-action:none}`, `<div id="game">`.
`src/main.ts`: `new Phaser.Game({ type: Phaser.AUTO, parent: 'game', backgroundColor: '#1565c0', scale: { mode: Phaser.Scale.RESIZE, width: '100%', height: '100%' }, scene: [] })`.
Phaser 4의 API가 헷갈리면 `node_modules/phaser/types/phaser.d.ts`를 확인한다.

Run: `npm run typecheck && npm run build` / Expected: 오류 없이 `dist/` 생성.

- [ ] **Step 7: Commit**

```bash
git add package.json package-lock.json tsconfig.json vite.config.ts index.html src tests
git commit -m "chore: scaffold Vite + Phaser project with number formatting"
```

---

### Task 2: 스테이지 난이도와 경제

**Files:**
- Create: `src/logic/balance.ts`
- Test: `tests/logic/balance.test.ts`

**Interfaces:**
- Produces:
  ```ts
  export type PigKind = 'normal' | 'gold';
  export interface StageConfig {
    stage: number; totalPigs: number; maxOnScreen: number; pigHp: number;
    timeLimit: number;      // 초
    pigSpeed: number;       // 단위/초 (layout.unit 곱하기 전)
    coinsPerPig: number;
    goldChance: number;     // 0.08
    goldHpMult: number;     // 5
    goldCoinMult: number;   // 8
    spawnInterval: number;  // 초, 0.35
  }
  export function stageConfig(stage: number): StageConfig;
  export function pigHp(cfg: StageConfig, kind: PigKind): number;
  export function pigCoins(cfg: StageConfig, kind: PigKind): number;
  ```

공식(모두 `Math.round`):
- `totalPigs = 20 + 4·(s−1)`
- `maxOnScreen = min(8 + floor((s−1)/3), 16)`
- `pigHp = round(30 · 1.18^(s−1))`
- `timeLimit = min(30 + 2·(s−1), 60)`
- `pigSpeed = min(40 + 3·(s−1), 120)`
- `coinsPerPig = round(5 · 1.12^(s−1))`
- 금 저금통: 체력 `pigHp·5`, 동전 `coinsPerPig·8`

설계 의도: 강화 없는 망치(피해 10, 초당 5회)로 1~2스테이지는 깨지고 3스테이지 즈음에서 막힌다. 1스테이지 수입은 약 160동전, 파워 첫 강화 비용은 20동전.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import { stageConfig, pigHp, pigCoins } from '../../src/logic/balance';

describe('stageConfig', () => {
  it('stage 1 is crowded from the start', () => {
    expect(stageConfig(1)).toMatchObject({
      totalPigs: 20, maxOnScreen: 8, pigHp: 30, timeLimit: 30,
      pigSpeed: 40, coinsPerPig: 5, goldChance: 0.08, spawnInterval: 0.35,
    });
  });
  it('stage 10 values', () => {
    expect(stageConfig(10)).toMatchObject({
      totalPigs: 56, maxOnScreen: 11, pigHp: 133, timeLimit: 48, pigSpeed: 67, coinsPerPig: 14,
    });
  });
  it('caps screen count, time and speed', () => {
    const c = stageConfig(100);
    expect(c.maxOnScreen).toBe(16);
    expect(c.timeLimit).toBe(60);
    expect(c.pigSpeed).toBe(120);
  });
  it('gets harder every stage and stays finite up to stage 300', () => {
    for (let s = 2; s <= 300; s++) {
      const prev = stageConfig(s - 1), c = stageConfig(s);
      expect(c.pigHp).toBeGreaterThanOrEqual(prev.pigHp);
      expect(c.totalPigs).toBeGreaterThan(prev.totalPigs);
      for (const v of [c.pigHp, c.coinsPerPig, pigHp(c, 'gold'), pigCoins(c, 'gold')]) {
        expect(Number.isFinite(v)).toBe(true);
      }
    }
  });
  it('gold pigs are tougher and richer', () => {
    const c = stageConfig(1);
    expect(pigHp(c, 'gold')).toBe(150);
    expect(pigCoins(c, 'gold')).toBe(40);
    expect(pigHp(c, 'normal')).toBe(30);
    expect(pigCoins(c, 'normal')).toBe(5);
  });
  it('treats stage < 1 as stage 1', () => {
    expect(stageConfig(0).stage).toBe(1);
  });
});
```

- [ ] **Step 2: 실패 확인** — Run: `npm test` / Expected: FAIL, 모듈 없음
- [ ] **Step 3: 구현** — `src/logic/balance.ts`. 계수는 파일 상단 상수로 둔다.
- [ ] **Step 4: 통과 확인** — Run: `npm test` / Expected: 모두 pass
- [ ] **Step 5: Commit** — `git commit -m "feat: add stage difficulty and coin curves"`

---

### Task 3: 망치 강화

**Files:**
- Create: `src/logic/upgrades.ts`
- Test: `tests/logic/upgrades.test.ts`

**Interfaces:**
- Produces:
  ```ts
  export type SkillId = 'power' | 'speed' | 'area' | 'crit' | 'chain';
  export type SkillLevels = Record<SkillId, number>;   // 0 = 잠김
  export const SKILL_ORDER: SkillId[];                  // power, speed, area, crit, chain
  export const SKILL_INFO: Record<SkillId, { label: string; icon: string }>;
  // label: 파워 / 연타 속도 / 범위 공격 / 크리티컬 / 연쇄 번개, icon: 💥 ⚡ 🌀 🎯 🔗
  export const START_LEVELS: SkillLevels;               // {power:1, speed:1, area:0, crit:0, chain:0}
  export interface HammerStats {
    damage: number; minIntervalMs: number;
    areaRadius: number; areaRatio: number;     // 단위(unit 곱하기 전), 잠김이면 radius 0
    critChance: number; critMultiplier: number;
    chainJumps: number; chainRange: number; chainRatio: number;
  }
  export function hammerStats(levels: SkillLevels): HammerStats;
  export function nextCost(skill: SkillId, level: number): number;  // level 0이면 해금 비용
  export function canBuy(coins: number, skill: SkillId, level: number): boolean;
  export function describeUpgrade(skill: SkillId, level: number): { now: string; next: string };
  ```

효과(레벨 L ≥ 1):
- 파워: `damage = round(10 · 1.25^(L−1))` / 비용 `round(20 · 1.35^(L−1))`
- 연타 속도: `minIntervalMs = max(80, round(200 · 0.92^(L−1)))` / 비용 `round(25 · 1.4^(L−1))`
- 범위: `areaRadius = 30 + 12·L`, `areaRatio = 0.5` / 해금 300, 이후 `round(150 · 1.4^(L−1))`
- 크리티컬: `critChance = min(0.5, 0.05 + 0.03·(L−1))`, `critMultiplier = 3` / 해금 500, 이후 `round(200 · 1.4^(L−1))`
- 연쇄 번개: `chainJumps = L + 1`, `chainRange = 140`, `chainRatio = 0.6` / 해금 1500, 이후 `round(400 · 1.45^(L−1))`
- 잠김(L=0): areaRadius 0, critChance 0, chainJumps 0.

`describeUpgrade` 문구(강화 화면 "전 → 후"에 그대로 씀):
- power `"-10"` → `"-13"`, speed `"초당 5.0회"` → `"초당 5.4회"`(1000/interval, 소수 1자리), area `"반경 42"`, crit `"5%"`, chain `"2회"`. 잠김일 때 `now`는 `"잠김"`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import { hammerStats, nextCost, canBuy, describeUpgrade, START_LEVELS } from '../../src/logic/upgrades';

describe('hammerStats', () => {
  it('starting hammer', () => {
    expect(hammerStats(START_LEVELS)).toEqual({
      damage: 10, minIntervalMs: 200, areaRadius: 0, areaRatio: 0.5,
      critChance: 0, critMultiplier: 3, chainJumps: 0, chainRange: 140, chainRatio: 0.6,
    });
  });
  it('levels raise stats', () => {
    const s = hammerStats({ power: 5, speed: 30, area: 2, crit: 3, chain: 1 });
    expect(s.damage).toBe(24);
    expect(s.minIntervalMs).toBe(80);
    expect(s.areaRadius).toBe(54);
    expect(s.critChance).toBeCloseTo(0.11);
    expect(s.chainJumps).toBe(2);
  });
  it('crit chance caps at 50%', () => {
    expect(hammerStats({ ...START_LEVELS, crit: 99 }).critChance).toBe(0.5);
  });
});

describe('costs', () => {
  it('unlock costs and level costs', () => {
    expect(nextCost('power', 1)).toBe(20);
    expect(nextCost('power', 2)).toBe(27);
    expect(nextCost('area', 0)).toBe(300);
    expect(nextCost('crit', 0)).toBe(500);
    expect(nextCost('chain', 0)).toBe(1500);
    expect(nextCost('chain', 1)).toBe(400);
  });
  it('canBuy needs enough coins', () => {
    expect(canBuy(19, 'power', 1)).toBe(false);
    expect(canBuy(20, 'power', 1)).toBe(true);
  });
  it('costs stay finite at level 200', () => {
    for (const k of ['power', 'speed', 'area', 'crit', 'chain'] as const) {
      expect(Number.isFinite(nextCost(k, 200))).toBe(true);
    }
  });
});

describe('describeUpgrade', () => {
  it('shows before and after', () => {
    expect(describeUpgrade('power', 1)).toEqual({ now: '-10', next: '-13' });
    expect(describeUpgrade('speed', 1)).toEqual({ now: '초당 5.0회', next: '초당 5.4회' });
    expect(describeUpgrade('area', 0)).toEqual({ now: '잠김', next: '반경 42' });
    expect(describeUpgrade('chain', 0)).toEqual({ now: '잠김', next: '2회' });
  });
});
```

- [ ] **Step 2: 실패 확인** — Run: `npm test` / Expected: FAIL
- [ ] **Step 3: 구현** — `src/logic/upgrades.ts`
- [ ] **Step 4: 통과 확인** — Run: `npm test` / Expected: 모두 pass
- [ ] **Step 5: Commit** — `git commit -m "feat: add hammer skills, costs and stats"`

---

### Task 4: 저장

**Files:**
- Create: `src/logic/save.ts`
- Test: `tests/logic/save.test.ts`

**Interfaces:**
- Consumes: `SkillLevels`, `START_LEVELS`, `SkillId` (Task 3)
- Produces:
  ```ts
  export const SAVE_KEY = 'piggy-smash.save.v1';
  export interface SaveData { version: 1; stage: number; coins: number; levels: SkillLevels; muted: boolean }
  export function defaultSave(): SaveData;  // stage 1, coins 0, START_LEVELS 복사본, muted false
  export function loadSave(storage: Pick<Storage, 'getItem'> | null): SaveData;
  export function writeSave(storage: Pick<Storage, 'setItem'> | null, data: SaveData): void;
  export function buySkill(data: SaveData, skill: SkillId): SaveData;  // 못 사면 같은 객체 반환
  ```

규칙: `loadSave`는 절대 throw하지 않는다. 필드별로 검증해서 잘못된 필드만 기본값으로 바꾼다(정수가 아니거나 음수인 stage/coins/levels → 기본값, stage < 1 → 1, power/speed < 1 → 1). `writeSave`는 저장소 오류(용량 초과, 비공개 모드)를 삼킨다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import { loadSave, writeSave, defaultSave, buySkill, SAVE_KEY } from '../../src/logic/save';

const mem = () => { const m = new Map<string, string>(); return {
  getItem: (k: string) => m.get(k) ?? null, setItem: (k: string, v: string) => void m.set(k, v), m }; };

describe('save', () => {
  it('returns defaults when empty', () => {
    expect(loadSave(mem())).toEqual(defaultSave());
  });
  it('round-trips', () => {
    const s = mem();
    const data = { ...defaultSave(), stage: 7, coins: 3410, muted: true };
    writeSave(s, data);
    expect(loadSave(s)).toEqual(data);
  });
  it('survives corrupt JSON and wrong types', () => {
    const s = mem();
    s.setItem(SAVE_KEY, '{nope');
    expect(loadSave(s)).toEqual(defaultSave());
    s.setItem(SAVE_KEY, JSON.stringify({ stage: -3, coins: 'lots', levels: { power: 0, chain: 2.5 }, muted: 1 }));
    expect(loadSave(s)).toEqual(defaultSave());
  });
  it('keeps valid fields when others are broken', () => {
    const s = mem();
    s.setItem(SAVE_KEY, JSON.stringify({ stage: 4, coins: null }));
    expect(loadSave(s)).toMatchObject({ stage: 4, coins: 0 });
  });
  it('never throws when storage throws or is missing', () => {
    const bad = { getItem: () => { throw new Error('denied'); }, setItem: () => { throw new Error('full'); } };
    expect(loadSave(bad)).toEqual(defaultSave());
    expect(() => writeSave(bad, defaultSave())).not.toThrow();
    expect(loadSave(null)).toEqual(defaultSave());
  });
  it('buySkill spends coins and raises level', () => {
    const d = { ...defaultSave(), coins: 25 };
    const after = buySkill(d, 'power');
    expect(after.coins).toBe(5);
    expect(after.levels.power).toBe(2);
    expect(d.levels.power).toBe(1);               // 원본 불변
    expect(buySkill(after, 'power')).toBe(after); // 돈 부족
  });
});
```

- [ ] **Step 2: 실패 확인** — Run: `npm test` / Expected: FAIL
- [ ] **Step 3: 구현** — `src/logic/save.ts`
- [ ] **Step 4: 통과 확인** — Run: `npm test` / Expected: 모두 pass
- [ ] **Step 5: Commit** — `git commit -m "feat: add crash-proof save and skill purchase"`

---

### Task 5: 타격 판정

**Files:**
- Create: `src/logic/combat.ts`
- Test: `tests/logic/combat.test.ts`

**Interfaces:**
- Consumes: `HammerStats` (Task 3)
- Produces:
  ```ts
  export interface Target { id: number; x: number; y: number; radius: number; hp: number }
  export interface Hit { id: number; damage: number; kind: 'direct' | 'area' | 'chain'; crit: boolean }
  export interface TapResult { hits: Hit[]; chain: Array<{ from: number; to: number }>; crit: boolean }
  export function resolveTap(tap: { x: number; y: number }, targets: Target[], stats: HammerStats,
                             unit: number, rng: () => number): TapResult;
  export class SwingGate { constructor(minIntervalMs: number); setInterval(ms: number): void; trySwing(nowMs: number): boolean }
  ```

규칙:
- 직접 타격: 터치점이 원 안에 들어간 대상 중 **중심이 터치점에 가장 가까운 것** 하나. 피해 `stats.damage`.
- 크리티컬: 터치당 `rng()` 한 번, `< critChance`이면 이 터치의 모든 피해 × `critMultiplier`.
- 범위: `areaRadius > 0`이면 터치점에서 `areaRadius·unit` 안(대상 원과 겹치면 포함)에 있는 직접 대상 외 모든 대상에게 `round(damage·areaRatio)`. 빗나가도(직접 대상 없음) 범위 피해는 들어간다.
- 연쇄 번개: 직접 대상이 있을 때만. 직접 대상에서 시작해 `chainRange·unit` 안의 **아직 번개 맞지 않은 가장 가까운 대상**으로 최대 `chainJumps`번 튄다. 각 `round(damage·chainRatio)`. 한 대상이 범위와 번개를 둘 다 맞을 수 있다.
- 피해는 `max(1, …)`. `resolveTap`은 대상의 hp를 바꾸지 않는다(호출 쪽이 적용).
- 거리는 중심 간 거리. 대상 반지름(`Target.radius`)은 이미 화면 픽셀이라 unit을 곱하지 않는다.
- `hits` 순서: 직접 → 범위(대상 배열 순) → 번개(튄 순서).
- `SwingGate.trySwing(now)`: 직전 성공 이후 `minIntervalMs` 이상 지났으면 true를 반환하고 시각을 갱신, 아니면 false(쌓지 않음). 첫 호출은 항상 true.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import { resolveTap, SwingGate } from '../../src/logic/combat';
import { hammerStats, START_LEVELS } from '../../src/logic/upgrades';

const base = hammerStats(START_LEVELS); // damage 10, 범위·크리·번개 없음
const T = (id: number, x: number, y: number) => ({ id, x, y, radius: 20, hp: 30 });
const never = () => 0.99, always = () => 0;

describe('resolveTap', () => {
  it('hits the target whose center is closest to the tap', () => {
    const r = resolveTap({ x: 15, y: 0 }, [T(1, 0, 0), T(2, 25, 0)], base, 1, never); // 거리 15 vs 10
    expect(r.hits).toEqual([{ id: 2, damage: 10, kind: 'direct', crit: false }]);
  });
  it('misses cleanly', () => {
    expect(resolveTap({ x: 200, y: 200 }, [T(1, 0, 0)], base, 1, never).hits).toEqual([]);
  });
  it('crit multiplies all damage from the tap', () => {
    const s = { ...base, critChance: 0.1, areaRadius: 60 };
    const r = resolveTap({ x: 0, y: 0 }, [T(1, 0, 0), T(2, 50, 0)], s, 1, always);
    expect(r.crit).toBe(true);
    expect(r.hits).toEqual([
      { id: 1, damage: 30, kind: 'direct', crit: true },
      { id: 2, damage: 15, kind: 'area', crit: true },
    ]);
  });
  it('area scales with unit and applies on a miss', () => {
    const s = { ...base, areaRadius: 40 };
    const targets = [T(1, 55, 0)]; // 55 ≤ 40+20 이면 맞고, unit 0.5면 55 > 20+20
    expect(resolveTap({ x: 0, y: 0 }, targets, s, 1, never).hits).toEqual([{ id: 1, damage: 5, kind: 'area', crit: false }]);
    expect(resolveTap({ x: 0, y: 0 }, targets, s, 0.5, never).hits).toEqual([]);
  });
  it('chain lightning jumps to nearest unhit targets within range', () => {
    const s = { ...base, chainJumps: 2, chainRange: 140 };
    const targets = [T(1, 0, 0), T(2, 100, 0), T(3, 200, 0), T(4, 500, 0)];
    const r = resolveTap({ x: 0, y: 0 }, targets, s, 1, never);
    expect(r.chain).toEqual([{ from: 1, to: 2 }, { from: 2, to: 3 }]);
    expect(r.hits.filter(h => h.kind === 'chain').map(h => [h.id, h.damage])).toEqual([[2, 6], [3, 6]]);
  });
  it('no chain on a miss', () => {
    const s = { ...base, chainJumps: 3 };
    expect(resolveTap({ x: 300, y: 300 }, [T(1, 0, 0)], s, 1, never).chain).toEqual([]);
  });
});

describe('SwingGate', () => {
  it('ignores taps inside the interval without queueing', () => {
    const g = new SwingGate(200);
    expect(g.trySwing(1000)).toBe(true);
    expect(g.trySwing(1050)).toBe(false);
    expect(g.trySwing(1100)).toBe(false);
    expect(g.trySwing(1200)).toBe(true);
    expect(g.trySwing(1201)).toBe(false);
  });
  it('setInterval applies to the next swing', () => {
    const g = new SwingGate(200);
    g.trySwing(0); g.setInterval(80);
    expect(g.trySwing(80)).toBe(true);
  });
});
```

- [ ] **Step 2: 실패 확인** — Run: `npm test` / Expected: FAIL
- [ ] **Step 3: 구현** — `src/logic/combat.ts`
- [ ] **Step 4: 통과 확인** — Run: `npm test` / Expected: 모두 pass
- [ ] **Step 5: Commit** — `git commit -m "feat: add tap resolution with area, crit, chain and swing gate"`

---

### Task 6: 한 판 진행

**Files:**
- Create: `src/logic/stageRun.ts`
- Test: `tests/logic/stageRun.test.ts`

**Interfaces:**
- Consumes: `StageConfig`, `PigKind`, `pigHp`, `pigCoins` (Task 2)
- Produces:
  ```ts
  export interface SpawnRequest { kind: PigKind; hp: number }
  export type RunStatus = 'playing' | 'cleared' | 'failed';
  export const MAX_DT = 0.25;      // 초
  export const COMBO_WINDOW = 1.5; // 초
  export class StageRun {
    constructor(cfg: StageConfig, rng: () => number);
    readonly cfg: StageConfig;
    timeLeft: number; status: RunStatus;
    spawned: number; broken: number; alive: number;
    coinsEarned: number; goldBroken: number; combo: number; bestCombo: number;
    get remaining(): number;              // totalPigs - broken
    start(): SpawnRequest[];              // maxOnScreen(또는 totalPigs 중 작은 수)만큼 즉시
    update(dt: number): SpawnRequest[];   // dt는 MAX_DT로 자름
    registerHit(): void;                  // 저금통을 맞힐 때마다 (한 터치에 여러 마리여도 1번)
    pigBroken(kind: PigKind): number;     // 받은 동전 반환
  }
  ```

규칙:
- `update`: playing이 아니면 아무것도 안 한다. `timeLeft -= dt`, 마지막 맞힘 후 `COMBO_WINDOW`가 지나면 `combo = 0`. 생성 타이머는 `alive < maxOnScreen && spawned < totalPigs`인 동안에만 dt만큼 쌓이고, `spawnInterval` 이상이 되면 하나 생성하고 그만큼 뺀다. 자리가 없으면 타이머는 0. 금 여부는 생성마다 `rng() < goldChance`.
- `pigBroken`: broken++, alive--, 동전 합산(금이면 goldBroken++). broken이 totalPigs가 되면 즉시 `cleared` — **같은 프레임에 시간이 0이 돼도 클리어가 우선**(update에서 시간 체크보다 먼저 판정되도록 pigBroken에서 상태를 바꾼다).
- `timeLeft <= 0`이면 `failed`, timeLeft는 0으로.
- 끝난 뒤의 pigBroken은 동전을 0 주고 상태를 바꾸지 않는다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import { StageRun, MAX_DT } from '../../src/logic/stageRun';
import { stageConfig } from '../../src/logic/balance';

const noGold = () => 0.99;
const small = { ...stageConfig(1), totalPigs: 3, maxOnScreen: 2 };

describe('StageRun', () => {
  it('fills the screen immediately on start', () => {
    const r = new StageRun(stageConfig(1), noGold);
    expect(r.start()).toHaveLength(8);
    expect(r.alive).toBe(8);
  });
  it('tops up one pig per spawnInterval', () => {
    const r = new StageRun(small, noGold);
    r.start(); r.pigBroken('normal');
    expect(r.update(0.2)).toHaveLength(0);
    expect(r.update(0.2)).toEqual([{ kind: 'normal', hp: 30 }]);
    expect(r.spawned).toBe(3);
    r.pigBroken('normal');
    expect(r.update(1)).toHaveLength(0); // totalPigs 다 나옴
  });
  it('rolls gold pigs', () => {
    const r = new StageRun(stageConfig(1), () => 0.01);
    expect(r.start()[0]).toEqual({ kind: 'gold', hp: 150 });
  });
  it('clears when every pig is broken, even on the last frame', () => {
    const r = new StageRun({ ...small, timeLimit: 1 }, noGold);
    r.start(); r.update(0.2); r.update(0.2);
    r.pigBroken('normal'); r.pigBroken('normal');
    r.update(0.25); r.update(0.25); r.update(0.08);
    r.pigBroken('gold');
    r.update(0.25);
    expect(r.status).toBe('cleared');
    expect(r.coinsEarned).toBe(5 + 5 + 40);
    expect(r.goldBroken).toBe(1);
  });
  it('fails when time runs out', () => {
    const r = new StageRun({ ...small, timeLimit: 0.3 }, noGold);
    r.start(); r.update(0.25); r.update(0.25);
    expect(r.status).toBe('failed');
    expect(r.timeLeft).toBe(0);
    expect(r.pigBroken('normal')).toBe(0);
  });
  it('clamps large frame delta', () => {
    const r = new StageRun(stageConfig(1), noGold);
    r.start(); r.update(30);
    expect(r.timeLeft).toBeCloseTo(30 - MAX_DT);
    expect(r.status).toBe('playing');
  });
  it('tracks combo and resets after 1.5s without hits', () => {
    const r = new StageRun(stageConfig(1), noGold);
    r.start();
    r.registerHit(); r.update(0.2); r.registerHit(); r.registerHit();
    expect(r.combo).toBe(3);
    for (let i = 0; i < 7; i++) r.update(0.25);
    expect(r.combo).toBe(0);
    expect(r.bestCombo).toBe(3);
  });
});
```

- [ ] **Step 2: 실패 확인** — Run: `npm test` / Expected: FAIL
- [ ] **Step 3: 구현** — `src/logic/stageRun.ts`
- [ ] **Step 4: 통과 확인** — Run: `npm test` / Expected: 모두 pass
- [ ] **Step 5: Commit** — `git commit -m "feat: add stage run state with spawning, timer and combo"`

---

### Task 7: 화면 배치

**Files:**
- Create: `src/logic/layout.ts`
- Test: `tests/logic/layout.test.ts`

**Interfaces:**
- Produces:
  ```ts
  export interface Rect { x: number; y: number; w: number; h: number }
  export interface Layout { width: number; height: number; unit: number; hud: Rect; arena: Rect }
  export function computeLayout(width: number, height: number): Layout;
  export function clampToArena(p: { x: number; y: number }, r: number, arena: Rect): { x: number; y: number };
  ```

규칙: `unit = clamp(min(width/390, height/760), 0.8, 2.2)`(기준 폰 390×760에서 1). HUD 높이 `round(72·unit)`, 위쪽 전체 폭. 경기장은 HUD 아래 남는 영역 전체에서 사방 `round(8·unit)` 안쪽. 저금통 반지름은 `21·unit`(금 `25·unit`), 씬이 이 값을 쓴다. `clampToArena`는 원 전체가 경기장 안에 들도록 중심을 옮긴다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import { computeLayout, clampToArena } from '../../src/logic/layout';

describe('computeLayout', () => {
  it('reference phone', () => {
    const l = computeLayout(390, 760);
    expect(l.unit).toBe(1);
    expect(l.hud).toEqual({ x: 0, y: 0, w: 390, h: 72 });
    expect(l.arena).toEqual({ x: 8, y: 80, w: 374, h: 672 });
  });
  it('folded cover screen (tall, narrow)', () => {
    const l = computeLayout(412, 915);
    expect(l.unit).toBeCloseTo(412 / 390);
    expect(l.arena.y + l.arena.h).toBeLessThanOrEqual(915);
  });
  it('unfolded inner screen (near square) scales pigs up', () => {
    const l = computeLayout(832, 750);
    expect(l.unit).toBeCloseTo(750 / 760);
    expect(l.arena.w).toBeGreaterThan(l.arena.h);
  });
  it('clamps unit for extreme sizes', () => {
    expect(computeLayout(200, 300).unit).toBe(0.8);
    expect(computeLayout(3000, 3000).unit).toBe(2.2);
  });
});

describe('clampToArena', () => {
  const arena = { x: 8, y: 80, w: 374, h: 672 };
  it('keeps the whole circle inside after a resize', () => {
    expect(clampToArena({ x: 800, y: 900 }, 21, arena)).toEqual({ x: 361, y: 731 });
    expect(clampToArena({ x: 0, y: 0 }, 21, arena)).toEqual({ x: 29, y: 101 });
  });
  it('leaves inside points alone', () => {
    expect(clampToArena({ x: 100, y: 300 }, 21, arena)).toEqual({ x: 100, y: 300 });
  });
});
```

- [ ] **Step 2: 실패 확인** — Run: `npm test` / Expected: FAIL
- [ ] **Step 3: 구현** — `src/logic/layout.ts`
- [ ] **Step 4: 통과 확인** — Run: `npm test` / Expected: 모두 pass
- [ ] **Step 5: Commit** — `git commit -m "feat: add responsive layout for folded and unfolded screens"`

---

### Task 8: 그림, 시작 화면, 공용 상태

**Files:**
- Create: `src/art/textures.ts`, `src/game/state.ts`, `src/scenes/BootScene.ts`, `src/scenes/TitleScene.ts`, `public/icon.svg`
- Modify: `src/main.ts` (씬 등록)

**Interfaces:**
- Consumes: `loadSave`, `writeSave`, `SaveData` (Task 4)
- Produces:
  - `generateTextures(scene: Phaser.Scene, scale: number): void` — 텍스처 키: `pig-normal`, `pig-gold`, `shard-normal`, `shard-gold`, `coin`, `hammer`, `burst`(충격 별), `spark`. `scale`은 `unit × devicePixelRatio`(최소 2)로 선명하게 그린다.
  - `game/state.ts`: `getSave(): SaveData`, `setSave(next: SaveData): void`(메모리 갱신 + `writeSave(localStorage)`), 저장소 접근은 `try { return window.localStorage } catch { return null }`.
  - 씬 키: `'boot' | 'title' | 'play' | 'result' | 'upgrade'`. Play는 `{ stage: number }`, Result는 `ResultData`(Task 11)를 받는다.

그림은 `docs/superpowers/specs/mockups/screens-flow.html`의 `#pig`, `#gold-pig`, 망치, 충격 별, 동전 SVG를 Phaser Graphics로 옮긴다(색은 Global Constraints). 금 저금통에는 흰 반짝이를 넣는다. `public/icon.svg`는 512×512 파란 배경 위 분홍 저금통 + 망치.

TitleScene: 배경 그라데이션, 큰 저금통 그림이 통통 튀는 트윈, 제목 "저금통 부수기", "현재 STAGE N", 노란 "시작" 버튼(굵은 테두리). 버튼을 누르면 `play`로 `{ stage: getSave().stage }`. (소리 잠금 해제 `sound.unlock()` 호출은 Task 10에서 이 버튼에 추가한다.)

- [ ] **Step 1: 구현** — 위 파일들. `main.ts`의 scene 목록에 Boot, Title 등록(나머지는 해당 Task에서 추가).
- [ ] **Step 2: 타입·빌드 확인** — Run: `npm run typecheck && npm test` / Expected: 오류 없음, 기존 테스트 모두 pass
- [ ] **Step 3: 화면 확인** — `npm run dev`를 띄우고 브라우저를 412×915(접은 화면)와 832×750(펼친 화면)로 바꿔 각각 스크린샷을 찍는다.
  Expected: 시작 화면이 두 크기 모두에서 잘리지 않고, 저금통 그림이 시안 C와 같은 모양(굵은 테두리, 코, 귀, 다리)이며, 콘솔 오류가 없다.
- [ ] **Step 4: Commit** — `git commit -m "feat: draw game art in code and add title screen"`

---

### Task 9: 플레이 화면 핵심

**Files:**
- Create: `src/scenes/PlayScene.ts`
- Modify: `src/main.ts`

**Interfaces:**
- Consumes: `stageConfig`, `pigHp` (Task 2), `hammerStats` (Task 3), `getSave` (Task 8), `resolveTap`, `SwingGate`, `Target` (Task 5), `StageRun` (Task 6), `computeLayout`, `clampToArena` (Task 7), 텍스처 키(Task 8)
- Produces: 끝나면 `this.scene.start('result', data: ResultData)`, `ResultData = { stage: number; cleared: boolean; coinsEarned: number; goldBroken: number; bestCombo: number; timeLeft: number }`(Task 11이 소비). Task 10이 연결할 훅: `onHitResolved(result: TapResult, tap: {x,y})`, `onPigBroken(pig, kind, coins)`, `onSwing(tap)` — 처음엔 비어 있는 메서드.

동작:
- `create`: `computeLayout(scale.width, scale.height)`, `StageRun.start()`의 요청만큼 저금통 생성. 저금통 객체 = 이미지 + 체력 바(머리 위 36·unit 폭, 30% 이하 주황) + `{ id, hp, maxHp, kind, vx, vy }`. 등장 위치는 경기장 안 무작위, 속도는 `pigSpeed·unit` 크기의 무작위 방향, 이동 방향에 맞춰 좌우 반전.
- `update(time, delta)`: `run.update(delta/1000)`의 요청 생성, 이동, 벽 반사, HUD 갱신(STAGE N, ⏱ 남은 초 올림, 🪙 동전 `formatNumber`, 진행 바 broken/totalPigs, "남은 저금통 N / 전체"). 상태가 끝나면 0.6초 뒤 result로.
- 입력: `pointerdown`(멀티터치 포함)마다 `gate.trySwing(time)`이 true일 때만 `onSwing` → `resolveTap(... unit, Math.random)` → 피해 적용, 맞힌 게 있으면 `run.registerHit()` 한 번 → 0 이하면 파괴(`run.pigBroken(kind)` → 저금통 제거). HUD 영역 터치는 무시.
- 크기 변경(`scale.on('resize')`): 레이아웃 재계산, HUD 재배치, 모든 저금통을 `clampToArena`로 이동하고 크기를 새 unit에 맞춤.
- 화면 이탈: `document.visibilitychange`가 hidden이면 `scene.pause()`, visible이면 `resume()`. 씬 종료 시 리스너 해제.

- [ ] **Step 1: 구현** — `PlayScene`. Title의 시작 버튼이 여기로 온다. Result가 아직 없으므로 임시로 끝나면 title로 돌아가게 하고, Task 11에서 result로 바꾼다.
- [ ] **Step 2: 타입·테스트 확인** — Run: `npm run typecheck && npm test` / Expected: 오류 없음
- [ ] **Step 3: 플레이 확인 (412×915)** — 브라우저에서 시작 → 확인 항목:
  - 시작 즉시 저금통 8마리가 돌아다닌다.
  - 클릭할 때마다 맞은 저금통 체력 바가 10씩 준다(30체력 → 3번에 파괴).
  - 아주 빠르게 연속 클릭해도 초당 5번 넘게 맞지 않는다.
  - 깨면 새 저금통이 0.35초 간격으로 채워지고, 남은 수가 줄어든다.
  - 20마리를 다 깨면 끝, 30초가 지나면 끝.
- [ ] **Step 4: 크기 변경 확인** — 플레이 중 412×915 → 832×750 → 412×915로 바꾼다.
  Expected: 저금통이 경기장 밖으로 나가지 않고, HUD가 새 폭에 맞고, 타이머와 남은 수가 그대로 이어진다. 콘솔 오류 없음.
- [ ] **Step 5: 이탈 확인** — 플레이 중 다른 탭으로 10초 갔다 돌아온다. Expected: 남은 시간이 거의 그대로다.
- [ ] **Step 6: Commit** — `git commit -m "feat: add play scene with spawning, tapping, HUD and resize handling"`

---

### Task 10: 타격감 (이펙트, 효과음, 진동, 음소거)

**Files:**
- Create: `src/fx/effects.ts`, `src/fx/sound.ts`, `src/fx/haptics.ts`
- Modify: `src/scenes/PlayScene.ts`(Task 9 훅 채우기, 음소거 버튼), `src/scenes/TitleScene.ts`(`sound.unlock()`)

**Interfaces:**
- Consumes: Task 9 훅, `TapResult` (Task 5), 텍스처(Task 8), `getSave`/`setSave` (Task 8, `muted`)
- Produces:
  - `sound.ts`: `unlock(): void`(첫 터치에서 AudioContext 생성/resume), `setMuted(m: boolean)`, `play(name: 'swing' | 'hit' | 'crit' | 'break' | 'coin' | 'zap'): void`. 소리는 Web Audio 오실레이터·노이즈로 합성한다. 같은 소리가 한 프레임에 여러 번 요청되면 한 번만 낸다(동전 짤랑이 수십 개 겹쳐 터지지 않게).
  - `haptics.ts`: `vibrate(ms: number): void` — `navigator.vibrate`가 없으면 아무것도 안 함. 음소거 상태에서도 진동은 유지.
  - `effects.ts`: `swingHammer`, `hitFlash`, `damageNumber`, `breakPig`, `coinBurstToCounter`, `lightning`, `shake` — 각 `(scene, ...)` 함수.

연출 값:
- **망치**: 터치점 위 오른쪽에서 들린 각도 −60°→+10°로 내려꽂힘. 걸리는 시간 `min(110ms, minIntervalMs·0.6)`, 끝나면 사라짐.
- **맞을 때**: 터치점에 `burst` 0.6→1.3배 커지며 160ms 페이드. 맞은 저금통 70ms 하얗게(tint fill) + scaleX 1.15/scaleY 0.85로 찌그러졌다 120ms에 복귀. 피해 숫자 위로 40·unit 떠오르며 500ms 페이드, 흰 글씨 검은 테두리. 크리티컬은 1.6배 크기, 노란색, "CRIT" 접두.
- **깨질 때**: `shard-*` 조각 6개가 사방으로 튀며 회전·낙하·페이드(450ms). 동전은 일반 4~6개, 금 14~18개가 튀어 오른 뒤 350ms 뒤부터 HUD 동전 카운터로 날아가고(곡선 트윈 500ms), 도착할 때 HUD 동전 아이콘이 1.2배로 튐. 동전 숫자는 도착 시점에 올라간다.
- **흔들림·진동**: 파괴 시 카메라 shake 100ms·강도 0.004, 크리티컬 160ms·0.008. 진동: 파괴 20ms, 크리티컬 35ms, 금 파괴 60ms.
- **번개**: `chain` 쌍마다 하늘색(`#e1f5fe`) 지그재그 선(마디 6개, 무작위 꺾임)을 두께 3·unit, 바깥 글로우 8·unit 반투명으로 그리고 180ms 페이드, 끝점에 `spark`.
- **효과음**: swing은 짧은 바람 소리, hit은 "깡"(금속성 짧은 고음), crit은 hit보다 낮고 큰 소리 + 고음, break은 도자기 깨지는 노이즈 버스트, coin은 "짤랑"(고음 두 음), zap은 지직거리는 소리.
- **음소거 버튼**: HUD 오른쪽 위 🔊/🔇, 누르면 `setSave({ ...getSave(), muted })`. 이 터치는 망치를 휘두르지 않는다.
- 동시 오브젝트 상한: 날아가는 동전 60개, 조각 80개. 넘으면 오래된 것부터 즉시 정리.

- [ ] **Step 1: 구현**
- [ ] **Step 2: 타입·테스트 확인** — Run: `npm run typecheck && npm test` / Expected: 오류 없음
- [ ] **Step 3: 타격감 확인** — 412×915로 플레이하며 스크린샷과 함께 확인한다. 개발용으로 강화 레벨을 올린 상태를 만들려면 콘솔에서 `localStorage`의 `piggy-smash.save.v1`을 `levels: {power:5,speed:10,area:3,crit:10,chain:3}`, `coins: 99999`로 바꾸고 새로고침한다.
  Expected: 망치 모션, 충격 별, 하얀 번쩍임과 찌그러짐, 피해 숫자, 조각과 동전이 튀고 카운터로 날아가는 것, 크리티컬 연출, 번개 줄기가 모두 보인다. 콘솔 오류 없음. 확인 후 저장 데이터를 원래대로 되돌린다.
- [ ] **Step 4: 성능 확인** — 위 강화 상태로 Chrome DevTools 성능 탭에서 4× CPU 스로틀을 걸고 10초 연타.
  Expected: 프레임이 대부분 50fps 이상. 미달이면 상한(동전·조각 수)을 낮춘다.
- [ ] **Step 5: Commit** — `git commit -m "feat: add hit effects, synthesized sounds, haptics and mute"`

---

### Task 11: 결과 화면과 강화 화면

**Files:**
- Create: `src/scenes/ResultScene.ts`, `src/scenes/UpgradeScene.ts`
- Modify: `src/scenes/PlayScene.ts`(끝나면 result로), `src/main.ts`

**Interfaces:**
- Consumes: `ResultData` (Task 9), `getSave`/`setSave` (Task 8), `buySkill` (Task 4), `SKILL_ORDER`, `SKILL_INFO`, `nextCost`, `canBuy`, `describeUpgrade` (Task 3), `formatNumber` (Task 1)

규칙:
- 결과를 받으면 **먼저 저장**한다: 동전 += coinsEarned, 클리어면 stage += 1. 이 저장은 결과 화면이 뜨기 전에 끝나야 한다(결과 화면에서 앱을 꺼도 진행이 남도록).
- 결과 화면(시안 ②): 반투명 어두운 배경 위 흰 카드. 클리어면 분홍 "CLEAR!", 실패면 회색 "TIME OVER". "STAGE N · 남은 시간 X초"(실패면 "남은 저금통 N"), 🪙 "+ 획득 동전", "금 저금통 N개 · 최고 콤보 N". 버튼: 초록 "강화하러 가기", 노랑 "다음 스테이지 ▶"(실패면 "다시 도전 ▶"). 노랑 버튼은 `play`로 `{ stage: getSave().stage }`.
- 강화 화면(시안 ③): 남색 배경, 제목 "망치 강화", 보유 동전. 스킬마다 한 줄: 아이콘·이름·"Lv.N"(잠김이면 🔒와 이름 회색), 아래 줄 `describeUpgrade`의 "now → next", 오른쪽 비용 버튼(초록, 잠김이면 노랑). 동전이 부족하면 버튼 회색이고 눌러도 반응 없음. 사면 `setSave(buySkill(...))` 후 줄과 동전 표시 갱신, 버튼이 1.15배 튀는 반응. 아래 "STAGE N 시작 ▶".
- 펼친 화면에서는 카드·목록 폭을 최대 `480·unit`으로 가운데 정렬.

- [ ] **Step 1: 구현**
- [ ] **Step 2: 타입·테스트 확인** — Run: `npm run typecheck && npm test` / Expected: 오류 없음
- [ ] **Step 3: 한 바퀴 확인** — 저장을 지우고(`localStorage.clear()`) 412×915에서: 시작 → 1스테이지 클리어 → 결과에 동전 표시 → 강화하러 가기 → 파워 Lv.1→2 구매(동전 20 감소, "-13 → -16"으로 바뀜) → STAGE 2 시작 → 새로고침해도 STAGE 2와 남은 동전·파워 Lv.2 유지. 일부러 실패해서 "TIME OVER"와 "다시 도전"이 나오고 동전은 남는지도 확인. 832×750에서도 두 화면을 스크린샷.
- [ ] **Step 4: Commit** — `git commit -m "feat: add result and upgrade screens with saving"`

---

### Task 12: 설치와 오프라인 (PWA)

**Files:**
- Create: `pwa-assets.config.ts`
- Modify: `vite.config.ts`, `index.html`

**Interfaces:**
- Consumes: `public/icon.svg` (Task 8)

- [ ] **Step 1: 아이콘 생성 설정** — `pwa-assets.config.ts`에서 `minimal2023Preset`, 원본 `public/icon.svg`. `package.json`에 `"icons": "pwa-assets-generator"` 스크립트 추가 후 실행.
- [ ] **Step 2: vite-plugin-pwa 설정** — `VitePWA({ registerType: 'autoUpdate', pwaAssets: { config: true }, manifest: { name: '저금통 부수기', short_name: '저금통', lang: 'ko', display: 'fullscreen', orientation: 'portrait', background_color: '#1565c0', theme_color: '#1565c0', start_url: './', scope: './' }, workbox: { globPatterns: ['**/*.{js,css,html,svg,png,ico,webmanifest}'] } })`. `index.html`에 `<meta name="theme-color" content="#1565c0">`.
- [ ] **Step 3: 오프라인 확인** — Run: `npm run build && npx vite preview`. 브라우저로 한 번 연 뒤 DevTools에서 서비스 워커 활성 확인, Network를 Offline으로 바꾸고 새로고침.
  Expected: 게임이 그대로 뜨고 플레이된다. Application 탭의 Manifest에 오류가 없고 설치 가능으로 표시된다.
- [ ] **Step 4: Commit** — `git commit -m "feat: make the game installable and playable offline"`

---

### Task 13: 배포와 폴드8 확인

**Files:**
- Create: `.github/workflows/deploy.yml`, `README.md`(설치 방법 3줄)

- [ ] **Step 1: 워크플로 작성** — main 푸시 시 `actions/checkout@v4` → `actions/setup-node@v4`(node 22, npm 캐시) → `npm ci` → `npm test` → `npm run build` → `actions/upload-pages-artifact@v3`(`dist`) → `actions/deploy-pages@v4`. 권한 `pages: write`, `id-token: write`.
- [ ] **Step 2: 사용자 확인 후 저장소 생성** — **실행 전에 사용자에게 묻는다:** "GitHub `ertai119` 계정에 공개 저장소 `piggy-smash`를 만들고 올려도 될까요?" 승인 후:
  ```bash
  gh repo create piggy-smash --public --source . --push
  gh api -X POST repos/ertai119/piggy-smash/pages -f build_type=workflow
  ```
  Expected: Actions 실행이 초록, `https://ertai119.github.io/piggy-smash/`가 열린다.
- [ ] **Step 3: 폴드8 확인 (사용자와 함께)** — 사용자에게 주소를 전달하고 아래를 확인받는다.
  1. 크롬 메뉴 → "홈 화면에 추가" → 아이콘으로 전체 화면 실행.
  2. 비행기 모드에서 아이콘으로 실행되는지.
  3. 접은 화면·펼친 화면 모두에서 플레이, 플레이 중 접고 펼치기.
  4. 소리와 진동이 나는지, 음소거 버튼.
  5. 강화한 상태에서 연타·번개가 겹칠 때 끊기는지.
  6. 2~4스테이지에서 강화 없이 막히고 강화하면 뚫리는지 — 너무 쉽거나 어렵다고 하면 `balance.ts`/`upgrades.ts` 계수를 조정하고 해당 테스트 기대값을 함께 바꾼다.
- [ ] **Step 4: Commit** — `git commit -m "chore: deploy to GitHub Pages"` 후 `git push`
