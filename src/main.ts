import Phaser from 'phaser';
import { DPR, cssSize } from './display';
import { BootScene } from './scenes/BootScene';
import { PlayScene } from './scenes/PlayScene';
import { ResultScene } from './scenes/ResultScene';
import { UpgradeScene } from './scenes/UpgradeScene';
import { TitleScene } from './scenes/TitleScene';

const size = cssSize();

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#1565c0',
  scale: { mode: Phaser.Scale.NONE, width: size.w, height: size.h, zoom: 1 / DPR },
  input: { activePointers: 3 },
  scene: [BootScene, TitleScene, PlayScene, ResultScene, UpgradeScene],
});

// 폰을 접거나 펼치면 창 크기가 바뀐다. 기기 픽셀 크기로 다시 맞춘다.
window.addEventListener('resize', () => {
  const s = cssSize();
  game.scale.resize(s.w, s.h);
});

// 개발 중 브라우저 콘솔에서 상태를 확인하기 위한 손잡이 (배포 빌드에는 없음)
if (import.meta.env.DEV) (window as unknown as { __game: Phaser.Game }).__game = game;
