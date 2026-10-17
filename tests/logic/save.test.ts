import { describe, it, expect } from 'vitest';
import { loadSave, writeSave, defaultSave, buySkill, SAVE_KEY } from '../../src/logic/save';

const mem = () => { const m = new Map<string, string>(); return {
  getItem: (k: string) => m.get(k) ?? null, setItem: (k: string, v: string) => void m.set(k, v), m }; };

describe('save', () => {
  it('returns defaults when empty', () => {
    expect(loadSave(mem())).toEqual(defaultSave());
  });
  it('round-trips', () => {
    const s = mem();
    const data = { ...defaultSave(), stage: 7, coins: 3410, muted: true };
    writeSave(s, data);
    expect(loadSave(s)).toEqual(data);
  });
  it('survives corrupt JSON and wrong types', () => {
    const s = mem();
    s.setItem(SAVE_KEY, '{nope');
    expect(loadSave(s)).toEqual(defaultSave());
    s.setItem(SAVE_KEY, JSON.stringify({ stage: -3, coins: 'lots', levels: { power: 0, chain: 2.5 }, muted: 1 }));
    expect(loadSave(s)).toEqual(defaultSave());
  });
  it('keeps valid fields when others are broken', () => {
    const s = mem();
    s.setItem(SAVE_KEY, JSON.stringify({ stage: 4, coins: null }));
    expect(loadSave(s)).toMatchObject({ stage: 4, coins: 0 });
  });
  it('never throws when storage throws or is missing', () => {
    const bad = { getItem: () => { throw new Error('denied'); }, setItem: () => { throw new Error('full'); } };
    expect(loadSave(bad)).toEqual(defaultSave());
    expect(() => writeSave(bad, defaultSave())).not.toThrow();
    expect(loadSave(null)).toEqual(defaultSave());
  });
  it('buySkill spends coins and raises level', () => {
    const d = { ...defaultSave(), coins: 25 };
    const after = buySkill(d, 'power');
    expect(after.coins).toBe(5);
    expect(after.levels.power).toBe(2);
    expect(d.levels.power).toBe(1);               // 원본 불변
    expect(buySkill(after, 'power')).toBe(after); // 돈 부족
  });
});
