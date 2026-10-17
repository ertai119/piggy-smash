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
