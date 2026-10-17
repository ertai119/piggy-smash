import Phaser from 'phaser';
import { ART_SIZE } from '../art/textures';
import { boldText } from '../display';

// 타격감 연출. 모든 크기는 unit(기기 픽셀) 기준.

const MAX_COINS = 60;
const MAX_SHARDS = 80;
const flyingCoins: Array<{ img: Phaser.GameObjects.Image; finish: () => void }> = [];
const shards: Phaser.GameObjects.Image[] = [];

type P = { x: number; y: number };

/** 망치가 들렸다가 터치점으로 내려꽂힌다. 손잡이 끝이 회전 중심. */
export function swingHammer(scene: Phaser.Scene, tap: P, unit: number, durationMs: number): void {
  const size = ART_SIZE.hammer * unit * 1.35;
  const h = scene.add
    .image(tap.x + 42 * unit, tap.y + 34 * unit, 'hammer')
    .setDisplaySize(size, size)
    .setOrigin(0.5, 0.94)
    .setAngle(25)
    .setDepth(30);
  scene.tweens.add({
    targets: h,
    angle: -52,
    duration: durationMs,
    ease: 'Quad.easeIn',
    onComplete: () => {
      scene.tweens.add({ targets: h, alpha: 0, angle: -40, duration: 90, delay: 40, onComplete: () => h.destroy() });
    },
  });
}

/** 터치점의 충격 별 */
export function impactBurst(scene: Phaser.Scene, at: P, unit: number, big: boolean): void {
  const base = ART_SIZE.burst * unit * (big ? 1.25 : 0.9);
  const b = scene.add.image(at.x, at.y, 'burst').setDisplaySize(base, base).setDepth(25);
  const s = b.scaleX;
  b.setScale(s * 0.6).setAngle(Phaser.Math.Between(0, 30));
  scene.tweens.add({ targets: b, scaleX: s * 1.3, scaleY: s * 1.3, alpha: 0, duration: 160, ease: 'Quad.easeOut', onComplete: () => b.destroy() });
}

/** 맞은 저금통: 하얗게 번쩍 + 찌그러졌다 복귀 */
export function hitFlash(scene: Phaser.Scene, sprite: Phaser.GameObjects.Image): void {
  sprite.setTint(0xffffff).setTintMode(Phaser.TintModes.FILL);
  scene.time.delayedCall(70, () => sprite.active && sprite.clearTint().setTintMode(Phaser.TintModes.MULTIPLY));
  const sx = sprite.getData('sx') as number;
  const sy = sprite.getData('sy') as number;
  scene.tweens.killTweensOf(sprite);
  sprite.setScale(sx * 1.15, sy * 0.85);
  scene.tweens.add({ targets: sprite, scaleX: sx, scaleY: sy, duration: 120, ease: 'Back.easeOut' });
}

export function damageNumber(scene: Phaser.Scene, at: P, dmg: number, crit: boolean, unit: number): void {
  const t = boldText(scene, at.x + Phaser.Math.Between(-8, 8) * unit, at.y - 18 * unit, crit ? `CRIT ${dmg}` : `-${dmg}`, unit, crit ? 26 : 17, crit ? '#ffca28' : '#ffffff', crit ? 5 : 4).setDepth(40);
  if (crit) t.setScale(0.5);
  scene.tweens.add({ targets: t, y: t.y - 40 * unit, alpha: 0, duration: 500, ease: 'Cubic.easeOut', onComplete: () => t.destroy() });
  if (crit) scene.tweens.add({ targets: t, scale: 1, duration: 140, ease: 'Back.easeOut' });
}

/** 저금통이 조각으로 흩어진다 */
export function breakPig(scene: Phaser.Scene, at: P, gold: boolean, unit: number): void {
  const key = gold ? 'shard-gold' : 'shard-normal';
  const size = ART_SIZE[key] * unit * (gold ? 1.3 : 1.1);
  for (let i = 0; i < 6; i++) {
    while (shards.length >= MAX_SHARDS) shards.shift()?.destroy();
    const s = scene.add.image(at.x, at.y, key).setDisplaySize(size, size).setDepth(15).setAngle(Phaser.Math.Between(0, 360));
    shards.push(s);
    const a = (Math.PI * 2 * i) / 6 + Math.random() * 0.6;
    const d = Phaser.Math.Between(30, 60) * unit;
    scene.tweens.add({
      targets: s,
      x: at.x + Math.cos(a) * d,
      y: at.y + Math.sin(a) * d + 30 * unit,
      angle: s.angle + Phaser.Math.Between(-360, 360),
      alpha: 0,
      duration: 450,
      ease: 'Quad.easeOut',
      onComplete: () => {
        const idx = shards.indexOf(s);
        if (idx >= 0) shards.splice(idx, 1);
        s.destroy();
      },
    });
  }
}

/**
 * 동전이 튀어 오른 뒤 HUD 동전 카운터로 날아간다.
 * 각 동전이 도착할 때 onArrive(그 동전이 가진 값)를 부른다. 값의 합 = total.
 */
export function coinBurstToCounter(scene: Phaser.Scene, at: P, visualCount: number, total: number, target: () => P, unit: number, onArrive: (value: number) => void): void {
  const n = Math.max(1, visualCount);
  const each = Math.floor(total / n);
  const size = ART_SIZE.coin * unit * 1.1;
  for (let i = 0; i < n; i++) {
    const value = i === n - 1 ? total - each * (n - 1) : each;
    while (flyingCoins.length >= MAX_COINS) flyingCoins.shift()?.finish();
    const img = scene.add.image(at.x, at.y, 'coin').setDisplaySize(size, size).setDepth(35);
    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      const idx = flyingCoins.findIndex((c) => c.img === img);
      if (idx >= 0) flyingCoins.splice(idx, 1);
      scene.tweens.killTweensOf(img);
      img.destroy();
      onArrive(value);
    };
    flyingCoins.push({ img, finish });
    const a = Math.random() * Math.PI * 2;
    const d = Phaser.Math.Between(25, 65) * unit;
    scene.tweens.add({
      targets: img,
      x: at.x + Math.cos(a) * d,
      y: at.y + Math.sin(a) * d - 20 * unit,
      duration: 300,
      ease: 'Cubic.easeOut',
      onComplete: () => {
        const to = target();
        scene.tweens.add({ targets: img, x: to.x, y: to.y, scale: img.scale * 0.7, duration: 500, delay: 50 + i * 18, ease: 'Cubic.easeIn', onComplete: finish });
      },
    });
  }
}

/** 지그재그 번개 줄기 */
export function lightning(scene: Phaser.Scene, from: P, to: P, unit: number): void {
  const pts: P[] = [from];
  const segs = 6;
  const nx = -(to.y - from.y), ny = to.x - from.x;
  const len = Math.hypot(nx, ny) || 1;
  for (let i = 1; i < segs; i++) {
    const t = i / segs;
    const off = Phaser.Math.FloatBetween(-12, 12) * unit;
    pts.push({ x: from.x + (to.x - from.x) * t + (nx / len) * off, y: from.y + (to.y - from.y) * t + (ny / len) * off });
  }
  pts.push(to);
  const g = scene.add.graphics().setDepth(28);
  const draw = (w: number, color: number, alpha: number) => {
    g.lineStyle(w, color, alpha).beginPath();
    g.moveTo(pts[0].x, pts[0].y);
    for (const p of pts.slice(1)) g.lineTo(p.x, p.y);
    g.strokePath();
  };
  draw(8 * unit, 0x81d4fa, 0.35);
  draw(3 * unit, 0xe1f5fe, 1);
  scene.tweens.add({ targets: g, alpha: 0, duration: 180, onComplete: () => g.destroy() });
  const s = scene.add.image(to.x, to.y, 'spark').setDisplaySize(ART_SIZE.spark * unit * 2, ART_SIZE.spark * unit * 2).setDepth(29);
  scene.tweens.add({ targets: s, scale: s.scale * 1.6, alpha: 0, angle: 90, duration: 220, onComplete: () => s.destroy() });
}

export function shake(scene: Phaser.Scene, ms: number, intensity: number): void {
  scene.cameras.main.shake(ms, intensity);
}

/** HUD 아이콘이 툭 튀는 반응 */
export function bump(scene: Phaser.Scene, obj: Phaser.GameObjects.Image | Phaser.GameObjects.Text): void {
  const sx = (obj.getData('sx') as number | undefined) ?? obj.scaleX;
  const sy = (obj.getData('sy') as number | undefined) ?? obj.scaleY;
  obj.setData('sx', sx).setData('sy', sy);
  scene.tweens.killTweensOf(obj);
  obj.setScale(sx * 1.25, sy * 1.25);
  scene.tweens.add({ targets: obj, scaleX: sx, scaleY: sy, duration: 140, ease: 'Quad.easeOut' });
}

/** 장면이 끝날 때 부른다(장면이 정리한 오브젝트를 다시 건드리지 않도록 목록만 비운다). */
export function resetEffects(): void {
  flyingCoins.length = 0;
  shards.length = 0;
}
