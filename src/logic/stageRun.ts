import { pigCoins, pigHp, type PigKind, type StageConfig } from './balance';

export interface SpawnRequest {
  kind: PigKind;
  hp: number;
}

export type RunStatus = 'playing' | 'cleared' | 'failed';

/** 앱 복귀 직후 같은 큰 프레임 간격이 타이머를 뭉텅이로 깎지 않게 자르는 상한(초) */
export const MAX_DT = 0.25;
/** 이 시간(초) 동안 아무것도 못 맞히면 콤보가 끊긴다 */
export const COMBO_WINDOW = 1.5;

/** 한 스테이지의 진행 상태. 화면과 무관한 규칙만 담는다. */
export class StageRun {
  timeLeft: number;
  status: RunStatus = 'playing';
  spawned = 0;
  broken = 0;
  alive = 0;
  coinsEarned = 0;
  goldBroken = 0;
  combo = 0;
  bestCombo = 0;

  private spawnTimer = 0;
  private sinceHit = 0;

  constructor(
    readonly cfg: StageConfig,
    private readonly rng: () => number,
  ) {
    this.timeLeft = cfg.timeLimit;
  }

  get remaining(): number {
    return this.cfg.totalPigs - this.broken;
  }

  start(): SpawnRequest[] {
    const n = Math.min(this.cfg.maxOnScreen, this.cfg.totalPigs);
    const out: SpawnRequest[] = [];
    for (let i = 0; i < n; i++) out.push(this.spawn());
    return out;
  }

  update(dt: number): SpawnRequest[] {
    if (this.status !== 'playing') return [];
    const step = Math.min(Math.max(dt, 0), MAX_DT);

    this.sinceHit += step;
    if (this.sinceHit >= COMBO_WINDOW) this.combo = 0;

    const out: SpawnRequest[] = [];
    if (this.alive < this.cfg.maxOnScreen && this.spawned < this.cfg.totalPigs) {
      this.spawnTimer += step;
      if (this.spawnTimer >= this.cfg.spawnInterval) {
        this.spawnTimer -= this.cfg.spawnInterval;
        out.push(this.spawn());
      }
    } else {
      this.spawnTimer = 0;
    }

    this.timeLeft -= step;
    if (this.timeLeft <= 0) {
      this.timeLeft = 0;
      this.status = 'failed';
    }
    return out;
  }

  /** 한 번의 터치로 무언가를 맞혔을 때 한 번 부른다 */
  registerHit(): void {
    this.combo += 1;
    this.sinceHit = 0;
    if (this.combo > this.bestCombo) this.bestCombo = this.combo;
  }

  /** 받은 동전을 돌려준다. 판이 끝난 뒤에는 0. */
  pigBroken(kind: PigKind): number {
    if (this.status !== 'playing') return 0;
    const coins = pigCoins(this.cfg, kind);
    this.broken += 1;
    this.alive = Math.max(0, this.alive - 1);
    this.coinsEarned += coins;
    if (kind === 'gold') this.goldBroken += 1;
    if (this.broken >= this.cfg.totalPigs) this.status = 'cleared';
    return coins;
  }

  private spawn(): SpawnRequest {
    const kind: PigKind = this.rng() < this.cfg.goldChance ? 'gold' : 'normal';
    this.spawned += 1;
    this.alive += 1;
    return { kind, hp: pigHp(this.cfg, kind) };
  }
}
