import Phaser from 'phaser';
import { ART_SIZE } from '../art/textures';
import { boldText, button, FONT, gameLayout } from '../display';
import { getSave } from '../game/state';
import { formatNumber } from '../logic/format';
import type { ResultData } from './PlayScene';

const BUTTON_LOCK_MS = 500;

/** 결과 화면(시안 ②). 저장은 PlayScene이 판이 끝나는 순간 이미 했다. */
export class ResultScene extends Phaser.Scene {
  private data_!: ResultData;

  constructor() {
    super('result');
  }

  create(data: ResultData): void {
    this.data_ = data;
    const L = gameLayout(this);
    const u = L.unit;
    const { width: W, height: H } = L;

    this.add.image(0, 0, 'bg').setOrigin(0).setDisplaySize(W, H);
    this.add.rectangle(0, 0, W, H, 0x000000, 0.35).setOrigin(0);

    const cw = Math.min(W - 40 * u, 320 * u);
    const ch = 300 * u;
    const cx = W / 2;
    const cy = H / 2;
    const card = this.add.graphics();
    card.fillStyle(0xffffff, 1).fillRoundedRect(cx - cw / 2, cy - ch / 2, cw, ch, 18 * u);
    card.lineStyle(3.5 * u, 0x000000, 1).strokeRoundedRect(cx - cw / 2, cy - ch / 2, cw, ch, 18 * u);

    const pigKey = data.cleared ? 'pig-gold' : 'pig-normal';
    const ps = ART_SIZE[pigKey] * u * 1.6;
    const pig = this.add.image(cx, cy - ch / 2 - 4 * u, pigKey).setDisplaySize(ps, ps);
    if (data.cleared) this.tweens.add({ targets: pig, y: pig.y - 10 * u, duration: 400, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    const top = cy - ch / 2;
    const title = data.cleared
      ? boldText(this, cx, top + 62 * u, 'CLEAR!', u, 36, '#ff4f8b', 6)
      : boldText(this, cx, top + 62 * u, 'TIME OVER', u, 32, '#9e9e9e', 6);
    title.setScale(0.4);
    this.tweens.add({ targets: title, scale: 1, duration: 320, ease: 'Back.easeOut' });

    const sub = data.cleared ? `STAGE ${data.stage} · 남은 시간 ${Math.ceil(data.timeLeft)}초` : `STAGE ${data.stage} · 남은 저금통 ${data.remaining}`;
    this.add.text(cx, top + 100 * u, sub, { fontFamily: FONT, fontSize: `${Math.round(14 * u)}px`, fontStyle: '700', color: '#333333' }).setOrigin(0.5);

    const coinY = top + 140 * u;
    this.add.image(cx - 46 * u, coinY, 'coin').setDisplaySize(ART_SIZE.coin * u * 1.6, ART_SIZE.coin * u * 1.6);
    const earned = boldText(this, cx + 18 * u, coinY, '+ 0', u, 24, '#333333');
    const counter = { v: 0 };
    this.tweens.add({ targets: counter, v: data.coinsEarned, duration: 600, ease: 'Cubic.easeOut', onUpdate: () => earned.setText(`+ ${formatNumber(counter.v)}`) });

    this.add
      .text(cx, top + 174 * u, `금 저금통 ${data.goldBroken}개 · 최고 콤보 ${data.bestCombo}`, { fontFamily: FONT, fontSize: `${Math.round(12 * u)}px`, color: '#888888' })
      .setOrigin(0.5);

    const bw = cw - 50 * u;
    const buttons = [
      button(this, cx, top + 216 * u, bw, 40 * u, '강화하러 가기', u, 0x76ff03, () => this.scene.start('upgrade'), 17),
      button(this, cx, top + 264 * u, bw, 38 * u, data.cleared ? '다음 스테이지 ▶' : '다시 도전 ▶', u, 0xffca28, () => this.scene.start('play', { stage: getSave().stage }), 16),
    ];
    // 시간이 끝날 때 연타하던 손가락이 버튼을 바로 누르지 않도록 잠깐 막는다
    for (const b of buttons) b.disableInteractive().setAlpha(0.6);
    this.time.delayedCall(BUTTON_LOCK_MS, () => buttons.forEach((b) => b.setInteractive().setAlpha(1)));

    const onResize = () => this.scene.restart(this.data_);
    this.scale.on('resize', onResize);
    this.events.once('shutdown', () => this.scale.off('resize', onResize));
  }
}
