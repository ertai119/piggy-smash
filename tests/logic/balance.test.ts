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
