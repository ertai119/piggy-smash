// 망치 스킬: 효과, 비용, 강화 화면 문구. 밸런스 조정은 이 파일의 상수만 바꾼다.

export type SkillId = 'power' | 'speed' | 'area' | 'crit' | 'chain';
/** 0 = 잠김 */
export type SkillLevels = Record<SkillId, number>;

export const SKILL_ORDER: SkillId[] = ['power', 'speed', 'area', 'crit', 'chain'];

export const SKILL_INFO: Record<SkillId, { label: string; icon: string }> = {
  power: { label: '파워', icon: '💥' },
  speed: { label: '연타 속도', icon: '⚡' },
  area: { label: '범위 공격', icon: '🌀' },
  crit: { label: '크리티컬', icon: '🎯' },
  chain: { label: '연쇄 번개', icon: '🔗' },
};

export const START_LEVELS: SkillLevels = { power: 1, speed: 1, area: 0, crit: 0, chain: 0 };

export interface HammerStats {
  damage: number;
  minIntervalMs: number;
  /** 단위(layout.unit 곱하기 전). 잠김이면 0 */
  areaRadius: number;
  areaRatio: number;
  critChance: number;
  critMultiplier: number;
  chainJumps: number;
  chainRange: number;
  chainRatio: number;
}

const AREA_RATIO = 0.5;
const CRIT_MULTIPLIER = 3;
const CHAIN_RANGE = 140;
const CHAIN_RATIO = 0.6;

const damageAt = (l: number) => Math.round(10 * 1.25 ** (l - 1));
const intervalAt = (l: number) => Math.max(80, Math.round(200 * 0.92 ** (l - 1)));
const areaRadiusAt = (l: number) => (l > 0 ? 30 + 12 * l : 0);
const critChanceAt = (l: number) => (l > 0 ? Math.min(0.5, 0.05 + 0.03 * (l - 1)) : 0);
const chainJumpsAt = (l: number) => (l > 0 ? l + 1 : 0);

/** [해금 비용(잠김일 때), 레벨 1→2 기본 비용, 증가율] */
const COSTS: Record<SkillId, [number, number, number]> = {
  power: [0, 20, 1.35],
  speed: [0, 25, 1.4],
  area: [300, 150, 1.4],
  crit: [500, 200, 1.4],
  chain: [1500, 400, 1.45],
};

export function hammerStats(levels: SkillLevels): HammerStats {
  return {
    damage: damageAt(Math.max(1, levels.power)),
    minIntervalMs: intervalAt(Math.max(1, levels.speed)),
    areaRadius: areaRadiusAt(levels.area),
    areaRatio: AREA_RATIO,
    critChance: critChanceAt(levels.crit),
    critMultiplier: CRIT_MULTIPLIER,
    chainJumps: chainJumpsAt(levels.chain),
    chainRange: CHAIN_RANGE,
    chainRatio: CHAIN_RATIO,
  };
}

/** 지금 레벨에서 다음 레벨로 가는 비용. level 0이면 해금 비용. */
export function nextCost(skill: SkillId, level: number): number {
  const [unlock, base, growth] = COSTS[skill];
  if (level <= 0) return unlock;
  return Math.round(base * growth ** (level - 1));
}

export function canBuy(coins: number, skill: SkillId, level: number): boolean {
  return coins >= nextCost(skill, level);
}

function effectText(skill: SkillId, level: number): string {
  switch (skill) {
    case 'power':
      return `-${damageAt(level)}`;
    case 'speed':
      return `초당 ${(1000 / intervalAt(level)).toFixed(1)}회`;
    case 'area':
      return `반경 ${areaRadiusAt(level)}`;
    case 'crit':
      return `${Math.round(critChanceAt(level) * 100)}%`;
    case 'chain':
      return `${chainJumpsAt(level)}회`;
  }
}

export function describeUpgrade(skill: SkillId, level: number): { now: string; next: string } {
  return {
    now: level <= 0 ? '잠김' : effectText(skill, level),
    next: effectText(skill, level + 1),
  };
}

const HAMMER_GROWTH = 0.15;
const HAMMER_MAX_SCALE = 2;

/** 범위 공격 레벨에 따른 망치·충격 별의 그림 크기 배율. 판정에는 영향 없음. */
export function hammerScale(areaLevel: number): number {
  return Math.min(HAMMER_MAX_SCALE, 1 + HAMMER_GROWTH * Math.max(0, areaLevel));
}
