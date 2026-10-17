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
