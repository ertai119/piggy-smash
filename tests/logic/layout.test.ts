import { describe, it, expect } from 'vitest';
import { computeLayout, clampToArena, scaleLayout } from '../../src/logic/layout';

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

describe('scaleLayout', () => {
  it('converts a CSS-pixel layout to device pixels', () => {
    const l = scaleLayout(computeLayout(390, 760), 2.5);
    expect(l.width).toBe(975);
    expect(l.unit).toBe(2.5);
    expect(l.hud).toEqual({ x: 0, y: 0, w: 975, h: 180 });
    expect(l.arena).toEqual({ x: 20, y: 200, w: 935, h: 1680 });
  });
});
