import Phaser from 'phaser';
import { ART_SIZE } from '../art/textures';
import { boldText, button, gameLayout } from '../display';
import { unlock } from '../fx/sound';
import { getSave } from '../game/state';

export class TitleScene extends Phaser.Scene {
  constructor() {
    super('title');
  }

  create(): void {
    const L = gameLayout(this);
    const u = L.unit;
    const { width: W, height: H } = L;

    this.add.image(0, 0, 'bg').setOrigin(0).setDisplaySize(W, H);

    boldText(this, W / 2, H * 0.17, '저금통 부수기', u, 44, '#ffffff', 8);

    const pigSize = ART_SIZE['pig-normal'] * u * 2.6;
    const pig = this.add.image(W / 2, H * 0.4, 'pig-normal').setDisplaySize(pigSize, pigSize);
    this.tweens.add({ targets: pig, y: pig.y - 14 * u, duration: 520, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    const hs = ART_SIZE.hammer * u * 2;
    const hammer = this.add.image(W / 2 + pigSize * 0.45, H * 0.4 - pigSize * 0.1, 'hammer').setDisplaySize(hs, hs);
    hammer.setOrigin(0.5, 0.9).setAngle(-35);
    this.tweens.add({ targets: hammer, angle: 5, duration: 260, yoyo: true, repeat: -1, repeatDelay: 500, ease: 'Quad.easeIn' });

    boldText(this, W / 2, H * 0.6, `STAGE ${getSave().stage}`, u, 24, '#ffca28', 5);

    button(this, W / 2, H * 0.72, 210 * u, 66 * u, '시작', u, 0xffca28, () => this.startGame(), 30);

    const onResize = () => this.scene.restart();
    this.scale.on('resize', onResize);
    this.events.once('shutdown', () => this.scale.off('resize', onResize));
  }

  private startGame(): void {
    unlock();
    if (this.scene.get('play')) this.scene.start('play', { stage: getSave().stage });
  }
}
