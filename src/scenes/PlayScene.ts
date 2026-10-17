import Phaser from 'phaser';
import { ART_SIZE } from '../art/textures';
import { boldText, gameLayout } from '../display';
import { getSave } from '../game/state';
import { stageConfig, type PigKind } from '../logic/balance';
import { resolveTap, SwingGate, type TapResult, type Target } from '../logic/combat';
import { formatNumber } from '../logic/format';
import { clampToArena, PIG_RADIUS, PIG_RADIUS_GOLD, type Layout } from '../logic/layout';
import { StageRun, type SpawnRequest } from '../logic/stageRun';
import { hammerStats, type HammerStats } from '../logic/upgrades';

export interface ResultData {
  stage: number;
  cleared: boolean;
  coinsEarned: number;
  goldBroken: number;
  bestCombo: number;
  timeLeft: number;
  remaining: number;
}

export interface Pig {
  id: number;
  kind: PigKind;
  hp: number;
  maxHp: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  sprite: Phaser.GameObjects.Image;
}

const END_DELAY_MS = 600;
const HP_LOW = 0.3;

export class PlayScene extends Phaser.Scene {
  protected L!: Layout;
  protected run!: StageRun;
  protected stats!: HammerStats;
  protected pigs = new Map<number, Pig>();
  /** 화면 동전 카운터에 이미 더해진 이번 판 동전 */
  protected shownCoins = 0;

  private nextId = 1;
  private gate!: SwingGate;
  private ending = false;
  private bg!: Phaser.GameObjects.Image;
  private bars!: Phaser.GameObjects.Graphics;
  private hud!: Phaser.GameObjects.Container;
  private hudStage!: Phaser.GameObjects.Text;
  private hudTime!: Phaser.GameObjects.Text;
  protected hudCoins!: Phaser.GameObjects.Text;
  protected hudCoinIcon!: Phaser.GameObjects.Image;
  private hudRemain!: Phaser.GameObjects.Text;
  private hudProgress!: Phaser.GameObjects.Graphics;

  constructor() {
    super('play');
  }

  create(data: { stage: number }): void {
    this.pigs.clear();
    this.nextId = 1;
    this.shownCoins = 0;
    this.ending = false;
    this.L = gameLayout(this);
    this.stats = hammerStats(getSave().levels);
    this.gate = new SwingGate(this.stats.minIntervalMs);
    this.run = new StageRun(stageConfig(data?.stage ?? getSave().stage), Math.random);

    this.bg = this.add.image(0, 0, 'bg').setOrigin(0).setDepth(-10);
    this.bars = this.add.graphics().setDepth(5);
    this.buildHud();
    this.fitBackground();

    for (const req of this.run.start()) this.spawnPig(req, false);

    this.input.on('pointerdown', this.onPointerDown, this);

    const onResize = () => this.relayout();
    this.scale.on('resize', onResize);
    const onVisibility = () => {
      if (document.hidden) this.scene.pause();
      else this.scene.resume();
    };
    document.addEventListener('visibilitychange', onVisibility);
    this.events.once('shutdown', () => {
      this.scale.off('resize', onResize);
      document.removeEventListener('visibilitychange', onVisibility);
      this.input.off('pointerdown', this.onPointerDown, this);
    });
  }

  update(_time: number, delta: number): void {
    if (this.ending) return;
    for (const req of this.run.update(delta / 1000)) this.spawnPig(req, true);
    this.movePigs(Math.min(delta / 1000, 0.1));
    this.drawBars();
    this.updateHud();
    if (this.run.status !== 'playing') this.finish();
  }

  // ---- 연출 훅 (Task 10에서 채운다) ----
  protected onSwing(_tap: { x: number; y: number }): void {}
  protected onHitResolved(_result: TapResult, _tap: { x: number; y: number }): void {}
  /** 동전 연출이 끝나면 addShownCoins를 불러야 한다. */
  protected onPigBroken(_pig: Pig, coins: number): void {
    this.addShownCoins(coins);
  }

  protected addShownCoins(n: number): void {
    this.shownCoins += n;
  }

  protected pigRadius(kind: PigKind): number {
    return (kind === 'gold' ? PIG_RADIUS_GOLD : PIG_RADIUS) * this.L.unit;
  }

  // ---- 저금통 ----
  private spawnPig(req: SpawnRequest, popIn: boolean): void {
    const r = this.pigRadius(req.kind);
    const a = this.L.arena;
    const x = Phaser.Math.FloatBetween(a.x + r, a.x + a.w - r);
    const y = Phaser.Math.FloatBetween(a.y + r, a.y + a.h - r);
    const speed = this.run.cfg.pigSpeed * this.L.unit * Phaser.Math.FloatBetween(0.75, 1.25);
    const dir = Phaser.Math.FloatBetween(0, Math.PI * 2);
    const key = req.kind === 'gold' ? 'pig-gold' : 'pig-normal';
    const size = ART_SIZE[key] * this.L.unit;
    const sprite = this.add.image(x, y, key).setDisplaySize(size, size).setDepth(req.kind === 'gold' ? 3 : 2);
    const pig: Pig = { id: this.nextId++, kind: req.kind, hp: req.hp, maxHp: req.hp, x, y, vx: Math.cos(dir) * speed, vy: Math.sin(dir) * speed, sprite };
    sprite.setFlipX(pig.vx < 0);
    if (popIn) {
      const sx = sprite.scaleX, sy = sprite.scaleY;
      sprite.setScale(0);
      this.tweens.add({ targets: sprite, scaleX: sx, scaleY: sy, duration: 220, ease: 'Back.easeOut' });
    }
    this.pigs.set(pig.id, pig);
  }

  private movePigs(dt: number): void {
    const a = this.L.arena;
    const t = this.time.now / 1000;
    for (const p of this.pigs.values()) {
      const r = this.pigRadius(p.kind);
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.x < a.x + r || p.x > a.x + a.w - r) {
        p.vx = -p.vx;
        p.sprite.setFlipX(p.vx < 0);
      }
      if (p.y < a.y + r || p.y > a.y + a.h - r) p.vy = -p.vy;
      const c = clampToArena(p, r, a);
      p.x = c.x;
      p.y = c.y;
      // 걷는 느낌: 살짝 뒤뚱거림
      p.sprite.setPosition(p.x, p.y + Math.sin(t * 12 + p.id) * 1.5 * this.L.unit);
      p.sprite.setAngle(Math.sin(t * 10 + p.id) * 4);
    }
  }

  private drawBars(): void {
    const u = this.L.unit;
    this.bars.clear();
    for (const p of this.pigs.values()) {
      const w = (p.kind === 'gold' ? 44 : 36) * u;
      const h = (p.kind === 'gold' ? 6 : 5) * u;
      const x = p.x - w / 2;
      const y = p.y - this.pigRadius(p.kind) - 12 * u;
      const ratio = Math.max(0, p.hp / p.maxHp);
      this.bars.fillStyle(0x333333, 1).fillRoundedRect(x, y, w, h, h / 2);
      this.bars.fillStyle(ratio <= HP_LOW ? 0xff7043 : 0x76ff03, 1).fillRoundedRect(x, y, Math.max(h, w * ratio), h, h / 2);
      this.bars.lineStyle(1.5 * u, 0x000000, 1).strokeRoundedRect(x, y, w, h, h / 2);
    }
  }

  // ---- 입력과 타격 ----
  private onPointerDown(pointer: Phaser.Input.Pointer): void {
    if (this.ending || pointer.y < this.L.hud.h) return;
    if (!this.gate.trySwing(this.time.now)) return;
    const tap = { x: pointer.x, y: pointer.y };
    this.onSwing(tap);

    const targets: Target[] = [...this.pigs.values()].map((p) => ({ id: p.id, x: p.x, y: p.y, radius: this.pigRadius(p.kind), hp: p.hp }));
    const result = resolveTap(tap, targets, this.stats, this.L.unit, Math.random);
    if (result.hits.length > 0) this.run.registerHit();
    for (const h of result.hits) {
      const p = this.pigs.get(h.id);
      if (p) p.hp -= h.damage;
    }
    this.onHitResolved(result, tap);
    for (const h of result.hits) {
      const p = this.pigs.get(h.id);
      if (p && p.hp <= 0) this.breakPig(p);
    }
  }

  private breakPig(p: Pig): void {
    this.pigs.delete(p.id);
    const coins = this.run.pigBroken(p.kind);
    p.sprite.destroy();
    this.onPigBroken(p, coins);
  }

  private finish(): void {
    this.ending = true;
    const r = this.run;
    const data: ResultData = {
      stage: r.cfg.stage,
      cleared: r.status === 'cleared',
      coinsEarned: r.coinsEarned,
      goldBroken: r.goldBroken,
      bestCombo: r.bestCombo,
      timeLeft: r.timeLeft,
      remaining: r.remaining,
    };
    this.time.delayedCall(END_DELAY_MS, () => {
      this.scene.start(this.scene.get('result') ? 'result' : 'title', data);
    });
  }

  // ---- HUD ----
  private buildHud(): void {
    this.hud?.destroy();
    const u = this.L.unit;
    const W = this.L.width;
    const m = 8 * u;
    const boxH = 30 * u;
    const y0 = 8 * u;
    const inner = W - m * 4;
    const ws = [inner * 0.3, inner * 0.28, inner * 0.42];
    const xs = [m, m * 2 + ws[0], m * 3 + ws[0] + ws[1]];

    const g = this.add.graphics();
    for (let i = 0; i < 3; i++) {
      g.fillStyle(0x0d1b3e, 1).fillRoundedRect(xs[i], y0, ws[i], boxH, 7 * u);
      g.lineStyle(2.5 * u, 0x000000, 1).strokeRoundedRect(xs[i], y0, ws[i], boxH, 7 * u);
    }
    const cy = y0 + boxH / 2;
    this.hudStage = boldText(this, xs[0] + ws[0] / 2, cy, '', u, 15);
    this.hudTime = boldText(this, xs[1] + ws[1] / 2, cy, '', u, 16);
    this.hudCoinIcon = this.add.image(xs[2] + 16 * u, cy, 'coin').setDisplaySize(ART_SIZE.coin * u, ART_SIZE.coin * u);
    this.hudCoins = boldText(this, xs[2] + ws[2] / 2 + 10 * u, cy, '', u, 16, '#ffca28');
    this.hudProgress = this.add.graphics();
    this.hudRemain = boldText(this, W / 2, y0 + boxH + 26 * u, '', u, 11);

    this.hud = this.add.container(0, 0, [g, this.hudStage, this.hudTime, this.hudCoinIcon, this.hudCoins, this.hudProgress, this.hudRemain]).setDepth(20);
  }

  private updateHud(): void {
    const u = this.L.unit;
    const r = this.run;
    this.hudStage.setText(`STAGE ${r.cfg.stage}`);
    this.hudTime.setText(`⏱ ${Math.ceil(r.timeLeft)}`);
    this.hudTime.setColor(r.timeLeft <= 5 ? '#ff7043' : '#ffffff');
    this.hudCoins.setText(formatNumber(getSave().coins + this.shownCoins));
    this.hudRemain.setText(`남은 저금통 ${r.remaining} / ${r.cfg.totalPigs}`);

    const m = 8 * u;
    const y = 8 * u + 30 * u + 6 * u;
    const w = this.L.width - m * 2;
    const h = 9 * u;
    const ratio = r.broken / r.cfg.totalPigs;
    this.hudProgress.clear();
    this.hudProgress.fillStyle(0x0d1b3e, 1).fillRoundedRect(m, y, w, h, h / 2);
    if (ratio > 0) this.hudProgress.fillStyle(0xff4f8b, 1).fillRoundedRect(m, y, Math.max(h, w * ratio), h, h / 2);
    this.hudProgress.lineStyle(2 * u, 0x000000, 1).strokeRoundedRect(m, y, w, h, h / 2);
  }

  private fitBackground(): void {
    this.bg.setDisplaySize(this.L.width, this.L.height);
  }

  /** 폰을 접거나 펼쳤을 때 */
  private relayout(): void {
    const oldUnit = this.L.unit;
    this.L = gameLayout(this);
    const k = this.L.unit / oldUnit;
    this.fitBackground();
    this.buildHud();
    for (const p of this.pigs.values()) {
      p.vx *= k;
      p.vy *= k;
      const c = clampToArena(p, this.pigRadius(p.kind), this.L.arena);
      p.x = c.x;
      p.y = c.y;
      const key = p.kind === 'gold' ? 'pig-gold' : 'pig-normal';
      p.sprite.setDisplaySize(ART_SIZE[key] * this.L.unit, ART_SIZE[key] * this.L.unit);
    }
  }
}
