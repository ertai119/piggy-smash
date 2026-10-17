import type { HammerStats } from './upgrades';

export interface Target {
  id: number;
  x: number;
  y: number;
  /** 화면 픽셀 */
  radius: number;
  hp: number;
}

export interface Hit {
  id: number;
  damage: number;
  kind: 'direct' | 'area' | 'chain';
  crit: boolean;
}

export interface TapResult {
  hits: Hit[];
  chain: Array<{ from: number; to: number }>;
  crit: boolean;
}

const dist = (ax: number, ay: number, bx: number, by: number) => Math.hypot(ax - bx, ay - by);

/**
 * 터치 한 번의 피해를 계산한다. 대상의 hp는 바꾸지 않는다.
 * 순서: 직접 → 범위(대상 배열 순) → 번개(튄 순서).
 */
export function resolveTap(
  tap: { x: number; y: number },
  targets: Target[],
  stats: HammerStats,
  unit: number,
  rng: () => number,
): TapResult {
  const crit = stats.critChance > 0 && rng() < stats.critChance;
  const mult = crit ? stats.critMultiplier : 1;
  const dmg = (ratio: number) => Math.max(1, Math.round(stats.damage * ratio * mult));
  const hits: Hit[] = [];
  const chain: TapResult['chain'] = [];

  let direct: Target | undefined;
  let best = Infinity;
  for (const t of targets) {
    const d = dist(tap.x, tap.y, t.x, t.y);
    if (d <= t.radius && d < best) {
      best = d;
      direct = t;
    }
  }
  if (direct) hits.push({ id: direct.id, damage: dmg(1), kind: 'direct', crit });

  if (stats.areaRadius > 0) {
    const r = stats.areaRadius * unit;
    for (const t of targets) {
      if (t !== direct && dist(tap.x, tap.y, t.x, t.y) <= r + t.radius) {
        hits.push({ id: t.id, damage: dmg(stats.areaRatio), kind: 'area', crit });
      }
    }
  }

  if (direct && stats.chainJumps > 0) {
    const range = stats.chainRange * unit;
    const struck = new Set<number>([direct.id]);
    let from = direct;
    for (let i = 0; i < stats.chainJumps; i++) {
      let next: Target | undefined;
      let nearest = Infinity;
      for (const t of targets) {
        if (struck.has(t.id)) continue;
        const d = dist(from.x, from.y, t.x, t.y);
        if (d <= range && d < nearest) {
          nearest = d;
          next = t;
        }
      }
      if (!next) break;
      struck.add(next.id);
      chain.push({ from: from.id, to: next.id });
      hits.push({ id: next.id, damage: dmg(stats.chainRatio), kind: 'chain', crit });
      from = next;
    }
  }

  return { hits, chain, crit };
}

/** 연타 간격 제한. 간격 안의 터치는 무시하고 쌓지 않는다. */
export class SwingGate {
  private last = -Infinity;

  constructor(private minIntervalMs: number) {}

  setInterval(ms: number): void {
    this.minIntervalMs = ms;
  }

  trySwing(nowMs: number): boolean {
    if (nowMs - this.last < this.minIntervalMs) return false;
    this.last = nowMs;
    return true;
  }
}
