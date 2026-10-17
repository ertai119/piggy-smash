export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface Layout {
  width: number;
  height: number;
  /** 기준 폰(390×760)에서 1. 모든 크기·속도·반경에 곱한다. */
  unit: number;
  hud: Rect;
  arena: Rect;
}

const REF_W = 390;
const REF_H = 760;
const UNIT_MIN = 0.8;
const UNIT_MAX = 2.2;
const HUD_H = 72;
const MARGIN = 8;

/** 일반 저금통 반지름(단위). 금 저금통은 PIG_RADIUS_GOLD. */
export const PIG_RADIUS = 21;
export const PIG_RADIUS_GOLD = 25;

export function computeLayout(width: number, height: number): Layout {
  const unit = Math.min(UNIT_MAX, Math.max(UNIT_MIN, Math.min(width / REF_W, height / REF_H)));
  const hudH = Math.round(HUD_H * unit);
  const m = Math.round(MARGIN * unit);
  return {
    width,
    height,
    unit,
    hud: { x: 0, y: 0, w: width, h: hudH },
    arena: { x: m, y: hudH + m, w: width - 2 * m, h: height - hudH - 2 * m },
  };
}

/** 반지름 r인 원 전체가 경기장 안에 들도록 중심을 옮긴다. */
export function clampToArena(p: { x: number; y: number }, r: number, arena: Rect): { x: number; y: number } {
  const clamp = (v: number, lo: number, hi: number) => (lo > hi ? (lo + hi) / 2 : Math.min(hi, Math.max(lo, v)));
  return {
    x: clamp(p.x, arena.x + r, arena.x + arena.w - r),
    y: clamp(p.y, arena.y + r, arena.y + arena.h - r),
  };
}
