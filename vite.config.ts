import { defineConfig } from 'vitest/config';

export default defineConfig({
  base: './',
  build: { chunkSizeWarningLimit: 2000 }, // Phaser 자체가 1MB 이상
  test: { include: ['tests/**/*.test.ts'] },
});
