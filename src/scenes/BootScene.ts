import Phaser from 'phaser';
import { generateTextures } from '../art/textures';
import { DPR } from '../display';
import { setMuted } from '../fx/sound';
import { getSave } from '../game/state';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('boot');
  }

  async create(): Promise<void> {
    setMuted(getSave().muted);
    // 가장 큰 단위(2.2)에서도 선명하도록 한 번 크게 그린다
    await generateTextures(this, 2.2 * DPR * 1.25);
    this.scene.start('title');
  }
}
