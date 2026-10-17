// 스테이지 난이도와 경제 곡선. 밸런스 조정은 이 파일의 상수만 바꾼다.

export type PigKind = 'normal' | 'gold';

export interface StageConfig {
  stage: number;
  totalPigs: number;
  maxOnScreen: number;
  pigHp: number;
  /** 초 */
  timeLimit: number;
  /** 단위/초 (layout.unit 곱하기 전) */
  pigSpeed: number;
  coinsPerPig: number;
  goldChance: number;
  goldHpMult: number;
  goldCoinMult: number;
  /** 초 */
  spawnInterval: number;
}

const PIGS_BASE = 20;
const PIGS_PER_STAGE = 4;
const SCREEN_BASE = 8;
const SCREEN_EVERY = 3;
const SCREEN_MAX = 16;
const HP_BASE = 30;
const HP_GROWTH = 1.18;
const TIME_BASE = 30;
const TIME_PER_STAGE = 2;
const TIME_MAX = 60;
const SPEED_BASE = 40;
const SPEED_PER_STAGE = 3;
const SPEED_MAX = 120;
const COINS_BASE = 5;
const COINS_GROWTH = 1.12;
const GOLD_CHANCE = 0.08;
const GOLD_HP_MULT = 5;
const GOLD_COIN_MULT = 8;
const SPAWN_INTERVAL = 0.35;
const SPAWN_SHRINK = 0.96;
const SPAWN_MIN = 0.1;
/** 모든 저금통이 나오는 데 걸리는 시간의 이 배수만큼은 제한 시간을 보장한다(높은 스테이지도 깰 수 있게) */
const TIME_SPAWN_MARGIN = 1.5;

const round3 = (v: number) => Math.round(v * 1000) / 1000;

export function stageConfig(stage: number): StageConfig {
  const s = Math.max(1, Math.floor(stage) || 1);
  const n = s - 1;
  const totalPigs = PIGS_BASE + PIGS_PER_STAGE * n;
  const maxOnScreen = Math.min(SCREEN_BASE + Math.floor(n / SCREEN_EVERY), SCREEN_MAX);
  const spawnInterval = Math.max(SPAWN_MIN, round3(SPAWN_INTERVAL * SPAWN_SHRINK ** n));
  const spawnTime = Math.ceil(round3((totalPigs - maxOnScreen) * spawnInterval * TIME_SPAWN_MARGIN));
  return {
    stage: s,
    totalPigs,
    maxOnScreen,
    pigHp: Math.round(HP_BASE * HP_GROWTH ** n),
    timeLimit: Math.max(Math.min(TIME_BASE + TIME_PER_STAGE * n, TIME_MAX), spawnTime),
    pigSpeed: Math.min(SPEED_BASE + SPEED_PER_STAGE * n, SPEED_MAX),
    coinsPerPig: Math.round(COINS_BASE * COINS_GROWTH ** n),
    goldChance: GOLD_CHANCE,
    goldHpMult: GOLD_HP_MULT,
    goldCoinMult: GOLD_COIN_MULT,
    spawnInterval,
  };
}

export function pigHp(cfg: StageConfig, kind: PigKind): number {
  return kind === 'gold' ? cfg.pigHp * cfg.goldHpMult : cfg.pigHp;
}

export function pigCoins(cfg: StageConfig, kind: PigKind): number {
  return kind === 'gold' ? cfg.coinsPerPig * cfg.goldCoinMult : cfg.coinsPerPig;
}
