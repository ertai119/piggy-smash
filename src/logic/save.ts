import { SKILL_ORDER, START_LEVELS, canBuy, nextCost, type SkillId, type SkillLevels } from './upgrades';

export const SAVE_KEY = 'piggy-smash.save.v1';

export interface SaveData {
  version: 1;
  stage: number;
  coins: number;
  levels: SkillLevels;
  muted: boolean;
}

export function defaultSave(): SaveData {
  return { version: 1, stage: 1, coins: 0, levels: { ...START_LEVELS }, muted: false };
}

const isCount = (v: unknown): v is number => typeof v === 'number' && Number.isInteger(v) && v >= 0;

/** 저장소가 없거나, 막혔거나, 데이터가 깨져도 절대 throw하지 않는다. 잘못된 필드만 기본값으로. */
export function loadSave(storage: Pick<Storage, 'getItem'> | null): SaveData {
  const save = defaultSave();
  let raw: unknown;
  try {
    const text = storage?.getItem(SAVE_KEY);
    if (!text) return save;
    raw = JSON.parse(text);
  } catch {
    return save;
  }
  if (typeof raw !== 'object' || raw === null) return save;
  const d = raw as Record<string, unknown>;

  if (isCount(d.stage) && d.stage >= 1) save.stage = d.stage;
  if (isCount(d.coins)) save.coins = d.coins;
  if (typeof d.muted === 'boolean') save.muted = d.muted;
  if (typeof d.levels === 'object' && d.levels !== null) {
    const levels = d.levels as Record<string, unknown>;
    for (const id of SKILL_ORDER) {
      const v = levels[id];
      const min = START_LEVELS[id];
      if (isCount(v) && v >= min) save.levels[id] = v;
    }
  }
  return save;
}

export function writeSave(storage: Pick<Storage, 'setItem'> | null, data: SaveData): void {
  try {
    storage?.setItem(SAVE_KEY, JSON.stringify(data));
  } catch {
    // 용량 초과·비공개 모드: 이번 저장만 건너뛴다
  }
}

/** 살 수 있으면 새 객체를, 못 사면 받은 객체를 그대로 돌려준다. */
export function buySkill(data: SaveData, skill: SkillId): SaveData {
  const level = data.levels[skill];
  if (!canBuy(data.coins, skill, level)) return data;
  return {
    ...data,
    coins: data.coins - nextCost(skill, level),
    levels: { ...data.levels, [skill]: level + 1 },
  };
}

/** 판이 끝났을 때 저장에 반영한다. 동전은 성공·실패와 관계없이 더하고, 클리어면 다음 스테이지로. */
export function applyResult(data: SaveData, result: { stage: number; cleared: boolean; coinsEarned: number }): SaveData {
  return {
    ...data,
    coins: data.coins + result.coinsEarned,
    stage: result.cleared ? Math.max(data.stage, result.stage + 1) : data.stage,
  };
}
