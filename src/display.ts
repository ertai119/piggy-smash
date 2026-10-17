import Phaser from 'phaser';
import { computeLayout, scaleLayout, type Layout } from './logic/layout';

/** 게임은 기기 픽셀 단위로 그린다(폴드8 DPR≈2.6에서 선명하게). 메모리를 위해 3에서 자른다. */
export const DPR = Math.min(3, Math.max(1, window.devicePixelRatio || 1));

export const FONT = 'system-ui, -apple-system, "Apple SD Gothic Neo", "Noto Sans KR", sans-serif';

/** 현재 게임 크기의 레이아웃(기기 픽셀). */
export function gameLayout(scene: Phaser.Scene): Layout {
  return scaleLayout(computeLayout(scene.scale.width / DPR, scene.scale.height / DPR), DPR);
}

export function cssSize(): { w: number; h: number } {
  return { w: Math.round(window.innerWidth * DPR), h: Math.round(window.innerHeight * DPR) };
}

/** 굵은 테두리 글씨(시안 C). size·stroke는 단위 값. */
export function boldText(
  scene: Phaser.Scene,
  x: number,
  y: number,
  str: string,
  unit: number,
  size: number,
  color = '#ffffff',
  stroke = 0,
): Phaser.GameObjects.Text {
  return scene.add
    .text(x, y, str, {
      fontFamily: FONT,
      fontSize: `${Math.round(size * unit)}px`,
      fontStyle: '900',
      color,
      stroke: '#000000',
      strokeThickness: Math.round(stroke * unit),
    })
    .setOrigin(0.5);
}

/** 시안 C의 둥근 버튼. 누르면 살짝 눌렸다가 onTap. */
export function button(
  scene: Phaser.Scene,
  x: number,
  y: number,
  w: number,
  h: number,
  label: string,
  unit: number,
  fill: number,
  onTap: () => void,
  textSize = 22,
): Phaser.GameObjects.Container {
  const g = scene.add.graphics();
  g.fillStyle(fill, 1).fillRoundedRect(-w / 2, -h / 2, w, h, 12 * unit);
  g.lineStyle(3.5 * unit, 0x000000, 1).strokeRoundedRect(-w / 2, -h / 2, w, h, 12 * unit);
  const t = boldText(scene, 0, 0, label, unit, textSize, '#111111');
  const c = scene.add.container(x, y, [g, t]).setSize(w, h);
  c.setInteractive({ useHandCursor: true });
  c.on('pointerdown', () => c.setScale(0.95));
  c.on('pointerout', () => c.setScale(1));
  c.on('pointerup', () => {
    c.setScale(1);
    onTap();
  });
  return c;
}
