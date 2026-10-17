const UNITS: Array<[number, string]> = [
  [1e12, 'T'],
  [1e9, 'B'],
  [1e6, 'M'],
  [1e3, 'K'],
];

/** 화면에 보여줄 숫자. 1만 미만은 쉼표, 그 이상은 K/M/B/T, 1000조 이상은 지수 표기. */
export function formatNumber(n: number): string {
  if (Number.isNaN(n)) return '0';
  if (!Number.isFinite(n)) return '∞';
  const v = Math.floor(n);
  if (v < 10_000) return v.toLocaleString('en-US');
  if (v >= 1e15) return v.toExponential(1).replace('+', '');
  for (const [size, suffix] of UNITS) {
    if (v >= size) return `${(v / size).toFixed(1)}${suffix}`;
  }
  return String(v);
}
