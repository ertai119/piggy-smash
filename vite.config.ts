import { VitePWA } from 'vite-plugin-pwa';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  base: './',
  build: { chunkSizeWarningLimit: 2000 }, // Phaser 자체가 1MB 이상
  plugins: [
    VitePWA({
      registerType: 'autoUpdate',
      pwaAssets: { config: true },
      manifest: {
        name: '저금통 부수기',
        short_name: '저금통',
        lang: 'ko',
        display: 'fullscreen',
        orientation: 'portrait',
        background_color: '#1565c0',
        theme_color: '#1565c0',
        start_url: './',
        scope: './',
      },
      workbox: { globPatterns: ['**/*.{js,css,html,svg,png,ico,webmanifest}'], maximumFileSizeToCacheInBytes: 4 * 1024 * 1024 },
    }),
  ],
  test: { include: ['tests/**/*.test.ts'] },
});
