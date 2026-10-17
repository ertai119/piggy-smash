import { describe, it, expect } from 'vitest';
import { hammerStats, hammerScale, nextCost, canBuy, describeUpgrade, START_LEVELS } from '../../src/logic/upgrades';

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

describe('hammerScale', () => {
  it('grows 15% per area level and caps at 2x', () => {
    expect(hammerScale(0)).toBe(1);
    expect(hammerScale(1)).toBeCloseTo(1.15);
    expect(hammerScale(3)).toBeCloseTo(1.45);
    expect(hammerScale(7)).toBe(2);
    expect(hammerScale(50)).toBe(2);
  });
});
