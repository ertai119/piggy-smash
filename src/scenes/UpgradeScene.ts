import Phaser from 'phaser';
import { ART_SIZE } from '../art/textures';
import { boldText, button, FONT, gameLayout } from '../display';
import { bump } from '../fx/effects';
import { play } from '../fx/sound';
import { getSave, setSave } from '../game/state';
import { formatNumber } from '../logic/format';
import { buySkill } from '../logic/save';
import { canBuy, describeUpgrade, nextCost, SKILL_INFO, SKILL_ORDER, type SkillId } from '../logic/upgrades';

/** 강화 화면(시안 ③) */
export class UpgradeScene extends Phaser.Scene {
  private rows = new Map<SkillId, Phaser.GameObjects.Container>();
  private coinText!: Phaser.GameObjects.Text;
  private coinIcon!: Phaser.GameObjects.Image;

  constructor() {
    super('upgrade');
  }

  create(): void {
    const L = gameLayout(this);
    const u = L.unit;
    const { width: W, height: H } = L;
    const colW = Math.min(W - 24 * u, 480 * u);
    const left = (W - colW) / 2;

    this.add.rectangle(0, 0, W, H, 0x0d1b3e).setOrigin(0);

    const hs = ART_SIZE.hammer * u * 0.75;
    this.add.image(left + 16 * u, 40 * u, 'hammer').setDisplaySize(hs, hs).setAngle(-30);
    boldText(this, left + 40 * u, 34 * u, '망치 강화', u, 22, '#ffffff', 4).setOrigin(0, 0.5);
    this.coinIcon = this.add.image(left + colW - 92 * u, 34 * u, 'coin').setDisplaySize(ART_SIZE.coin * u * 1.3, ART_SIZE.coin * u * 1.3);
    this.coinText = boldText(this, left + colW - 78 * u, 34 * u, '', u, 18, '#ffca28', 4).setOrigin(0, 0.5);

    const rowH = 64 * u;
    const gap = 10 * u;
    const startY = 72 * u;
    this.rows.clear();
    SKILL_ORDER.forEach((id, i) => {
      const c = this.add.container(left, startY + i * (rowH + gap));
      this.rows.set(id, c);
    });
    this.drawRows(colW, rowH, u);

    const lastY = startY + SKILL_ORDER.length * (rowH + gap);
    const btnY = Math.min(H - 44 * u, lastY + 40 * u);
    button(this, W / 2, btnY, Math.min(colW, 260 * u), 48 * u, `STAGE ${getSave().stage} 시작 ▶`, u, 0xffca28, () => this.scene.start('play', { stage: getSave().stage }), 18);

    const onResize = () => this.scene.restart();
    this.scale.on('resize', onResize);
    this.events.once('shutdown', () => this.scale.off('resize', onResize));
  }

  private drawRows(colW: number, rowH: number, u: number): void {
    const save = getSave();
    this.coinText.setText(formatNumber(save.coins));
    for (const id of SKILL_ORDER) {
      const c = this.rows.get(id)!;
      c.removeAll(true);
      const level = save.levels[id];
      const locked = level === 0;
      const info = SKILL_INFO[id];
      const cost = nextCost(id, level);
      const affordable = canBuy(save.coins, id, level);

      const g = this.add.graphics();
      g.fillStyle(locked ? 0x14264a : 0x1e3a6e, 1).fillRoundedRect(0, 0, colW, rowH, 10 * u);
      g.lineStyle(2.5 * u, 0x000000, 1).strokeRoundedRect(0, 0, colW, rowH, 10 * u);

      const name = locked ? `🔒 ${info.label}` : `${info.icon} ${info.label} Lv.${level}`;
      const title = this.add.text(14 * u, 12 * u, name, { fontFamily: FONT, fontSize: `${Math.round(16 * u)}px`, fontStyle: '800', color: locked ? '#7a8bab' : '#ffffff' });
      const d = describeUpgrade(id, level);
      const desc = this.add.text(14 * u, 38 * u, locked ? `해금하면 ${d.next}` : `${d.now} → ${d.next}`, { fontFamily: FONT, fontSize: `${Math.round(12 * u)}px`, fontStyle: '700', color: locked ? '#7a8bab' : '#9ecbff' });

      const bw = 96 * u;
      const bh = 38 * u;
      const fill = !affordable ? 0x6b7280 : locked ? 0xffca28 : 0x76ff03;
      const btn = button(this, colW - bw / 2 - 12 * u, rowH / 2, bw, bh, `🪙 ${formatNumber(cost)}`, u, fill, () => this.buy(id), 14);
      if (!affordable) btn.disableInteractive();

      c.add([g, title, desc, btn]);
    }
  }

  private buy(id: SkillId): void {
    const before = getSave();
    const after = buySkill(before, id);
    if (after === before) return;
    setSave(after);
    play('coin');
    const L = gameLayout(this);
    const u = L.unit;
    const colW = Math.min(L.width - 24 * u, 480 * u);
    this.drawRows(colW, 64 * u, u);
    bump(this, this.coinIcon);
    const row = this.rows.get(id)!;
    const btn = row.list[row.list.length - 1] as Phaser.GameObjects.Container;
    btn.setScale(1.15);
    this.tweens.add({ targets: btn, scale: 1, duration: 160, ease: 'Back.easeOut' });
  }
}
