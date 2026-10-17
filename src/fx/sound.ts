// 음원 파일 없이 Web Audio로 효과음을 합성한다.

export type SoundName = 'swing' | 'hit' | 'crit' | 'break' | 'coin' | 'zap';

let ctx: AudioContext | null = null;
let master: GainNode | null = null;
let noise: AudioBuffer | null = null;
let muted = false;
const thisFrame = new Set<SoundName>();
let clearScheduled = false;

/** 브라우저 정책상 첫 터치 안에서 불러야 소리가 난다. */
export function unlock(): void {
  try {
    if (!ctx) {
      ctx = new AudioContext();
      master = ctx.createGain();
      master.gain.value = 0.55;
      master.connect(ctx.destination);
      noise = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
      const d = noise.getChannelData(0);
      for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    }
    if (ctx.state === 'suspended') void ctx.resume();
  } catch {
    ctx = null; // 오디오를 못 쓰는 환경: 조용히 진행
  }
}

export function setMuted(m: boolean): void {
  muted = m;
}

export function isMuted(): boolean {
  return muted;
}

/** 같은 소리가 한 프레임에 여러 번 요청되면 한 번만 낸다. */
export function play(name: SoundName): void {
  if (muted || !ctx || !master || ctx.state !== 'running') return;
  if (thisFrame.has(name)) return;
  thisFrame.add(name);
  if (!clearScheduled) {
    clearScheduled = true;
    requestAnimationFrame(() => {
      thisFrame.clear();
      clearScheduled = false;
    });
  }
  SYNTH[name](ctx, master, ctx.currentTime);
}

function env(c: AudioContext, out: AudioNode, t: number, peak: number, attack: number, decay: number): GainNode {
  const g = c.createGain();
  g.gain.setValueAtTime(0.0001, t);
  g.gain.exponentialRampToValueAtTime(peak, t + attack);
  g.gain.exponentialRampToValueAtTime(0.0001, t + attack + decay);
  g.connect(out);
  return g;
}

function tone(c: AudioContext, out: AudioNode, t: number, type: OscillatorType, f0: number, f1: number, peak: number, decay: number): void {
  const o = c.createOscillator();
  o.type = type;
  o.frequency.setValueAtTime(f0, t);
  o.frequency.exponentialRampToValueAtTime(f1, t + decay);
  o.connect(env(c, out, t, peak, 0.003, decay));
  o.start(t);
  o.stop(t + decay + 0.05);
}

function burst(c: AudioContext, out: AudioNode, t: number, filter: BiquadFilterType, f0: number, f1: number, peak: number, decay: number): void {
  const s = c.createBufferSource();
  s.buffer = noise;
  const bq = c.createBiquadFilter();
  bq.type = filter;
  bq.frequency.setValueAtTime(f0, t);
  bq.frequency.exponentialRampToValueAtTime(f1, t + decay);
  s.connect(bq).connect(env(c, out, t, peak, 0.004, decay));
  s.start(t, Math.random() * 0.5);
  s.stop(t + decay + 0.05);
}

const SYNTH: Record<SoundName, (c: AudioContext, out: AudioNode, t: number) => void> = {
  // 휙 — 바람 가르는 소리
  swing: (c, out, t) => burst(c, out, t, 'bandpass', 700, 2600, 0.12, 0.09),
  // 깡 — 짧은 금속성 고음 + 타격 잡음
  hit: (c, out, t) => {
    tone(c, out, t, 'square', 1250, 900, 0.16, 0.11);
    tone(c, out, t, 'triangle', 2600, 2100, 0.12, 0.08);
    burst(c, out, t, 'highpass', 3000, 1500, 0.25, 0.03);
  },
  // 쾅 — 낮고 큰 소리 + 높은 울림
  crit: (c, out, t) => {
    tone(c, out, t, 'sawtooth', 420, 90, 0.35, 0.22);
    tone(c, out, t, 'sine', 2400, 1800, 0.2, 0.3);
    burst(c, out, t, 'lowpass', 3000, 300, 0.4, 0.12);
  },
  // 와장창 — 도자기 깨지는 잡음 + 파편 딸깍
  break: (c, out, t) => {
    burst(c, out, t, 'highpass', 1800, 900, 0.5, 0.26);
    for (let i = 0; i < 4; i++) {
      const dt = 0.015 + i * 0.03 + Math.random() * 0.02;
      tone(c, out, t + dt, 'triangle', 2600 + Math.random() * 1600, 2000, 0.12, 0.05);
    }
  },
  // 짤랑 — 높은 두 음
  coin: (c, out, t) => {
    tone(c, out, t, 'square', 1319, 1319, 0.07, 0.06);
    tone(c, out, t + 0.055, 'square', 1976, 1976, 0.07, 0.12);
  },
  // 지직 — 번개
  zap: (c, out, t) => {
    tone(c, out, t, 'sawtooth', 160, 60, 0.16, 0.18);
    burst(c, out, t, 'bandpass', 4000, 800, 0.3, 0.18);
  },
};
