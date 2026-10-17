import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

// Workbox는 사전 캐시 목록에 같은 URL이 두 번 있으면 설치 중 오류를 내고 아무것도 캐시하지 않는다.
// 배포와 똑같이 dist/로 production 빌드해서 확인한다.
describe('service worker precache', () => {
  it('lists every URL once and includes the game shell', { timeout: 60_000 }, () => {
    execFileSync('npx', ['vite', 'build', '--logLevel', 'error'], { stdio: 'pipe', env: { ...process.env, NODE_ENV: 'production' } });
    const sw = readFileSync('dist/sw.js', 'utf8');
    const urls = [...sw.matchAll(/url:"([^"]+)"/g)].map((m) => m[1]);
    expect(urls).toContain('index.html');
    expect(urls).toContain('manifest.webmanifest');
    expect(urls.some((u) => /^assets\/index-.*\.js$/.test(u))).toBe(true);
    expect(urls.length).toBe(new Set(urls).size);
  });
});
