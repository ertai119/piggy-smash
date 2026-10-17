import { describe, it, expect } from 'vitest';
import { formatNumber } from '../../src/logic/format';

describe('formatNumber', () => {
  it('uses commas below 10,000', () => {
    expect(formatNumber(0)).toBe('0');
    expect(formatNumber(1240)).toBe('1,240');
    expect(formatNumber(9999)).toBe('9,999');
  });
  it('abbreviates large numbers with one decimal', () => {
    expect(formatNumber(12_345)).toBe('12.3K');
    expect(formatNumber(4_560_000)).toBe('4.6M');
    expect(formatNumber(7_800_000_000)).toBe('7.8B');
    expect(formatNumber(2.5e12)).toBe('2.5T');
  });
  it('falls back to exponent beyond trillions and never prints NaN', () => {
    expect(formatNumber(3.2e16)).toBe('3.2e16');
    expect(formatNumber(Infinity)).toBe('∞');
    expect(formatNumber(NaN)).toBe('0');
  });
  it('floors fractions', () => {
    expect(formatNumber(12.9)).toBe('12');
  });
});
