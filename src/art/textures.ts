import Phaser from 'phaser';

// 시안 C(docs/superpowers/specs/mockups/screens-flow.html)의 SVG를 그대로 텍스처로 만든다.
// 텍스처는 한 번만 크게 그리고, 화면 크기가 바뀌면 표시 크기만 바꾼다.

const OUTLINE = 'stroke="#000" stroke-width="2.5"';

const pigSvg = (body: string, snout: string, sparkle: boolean, big: boolean) => {
  const k = big ? 25 / 21 : 1;
  return `<g transform="scale(${k})">
  <g ${OUTLINE}>
    <rect x="-12" y="12" width="7" height="9" rx="2" fill="${body}"/>
    <rect x="6" y="12" width="7" height="9" rx="2" fill="${body}"/>
    <ellipse cx="0" cy="0" rx="21" ry="16" fill="${body}"/>
    <path d="M-6,-15 l4,-7 l4,7z" fill="${snout}"/>
    <ellipse cx="18" cy="2" rx="7" ry="6" fill="${snout}"/>
    <rect x="-7" y="-15" width="10" height="3" rx="1.5" fill="#000" stroke="none"/>
  </g>
  <circle cx="16" cy="1" r="1.3" fill="#000"/><circle cx="20" cy="1" r="1.3" fill="#000"/>
  <circle cx="8" cy="-5" r="2.3" fill="#000"/>
  <ellipse cx="-9" cy="-7" rx="5" ry="2.5" fill="#fff" opacity=".45"/>
  ${sparkle ? '<path d="M-12,-5 l1.7,-4.3 l1.7,4.3 l4.3,1.7 l-4.3,1.7 l-1.7,4.3 l-1.7,-4.3 l-4.3,-1.7z" fill="#fff"/>' : ''}
</g>`;
};

/** [키, viewBox(정사각형 한 변), SVG 본문(원점이 중심)] */
const ART: Array<[string, number, string]> = [
  ['pig-normal', 56, pigSvg('#ff4f8b', '#ff80ab', false, false)],
  ['pig-gold', 66, pigSvg('#ffd54f', '#ffe082', true, true)],
  ['shard-normal', 20, `<path d="M-7,-6 L5,-8 L8,3 L-2,8 L-8,2z" fill="#ff4f8b" ${OUTLINE}/>`],
  ['shard-gold', 20, `<path d="M-7,-6 L5,-8 L8,3 L-2,8 L-8,2z" fill="#ffd54f" ${OUTLINE}/>`],
  [
    'coin',
    20,
    `<circle r="7.5" fill="#ffca28" stroke="#000" stroke-width="1.8"/>
     <circle r="4.6" fill="none" stroke="#c99400" stroke-width="1.2"/>
     <path d="M-3.5,-4 a5,5 0 0 1 4,-1.6" stroke="#fff" stroke-width="1.4" fill="none" stroke-linecap="round"/>`,
  ],
  [
    // 손잡이 끝(아래)이 회전 중심이 되도록 텍스처 아래쪽에 둔다
    'hammer',
    64,
    `<g transform="translate(0,-8)" ${OUTLINE}>
       <rect x="-4" y="0" width="8" height="36" rx="3" fill="#8d6e63"/>
       <rect x="-17" y="-14" width="34" height="18" rx="4" fill="#90a4ae"/>
       <rect x="-17" y="-14" width="34" height="5" rx="2" fill="#cfd8dc" stroke="none"/>
     </g>`,
  ],
  [
    'burst',
    64,
    `<polygon points="0,-30 7,-11 27,-16 12,0 27,14 5,9 0,28 -5,9 -27,14 -12,0 -27,-16 -7,-11"
       fill="#fff59d" stroke="#000" stroke-width="2"/>`,
  ],
  ['spark', 16, `<path d="M0,-7 L1.6,-1.6 L7,0 L1.6,1.6 L0,7 L-1.6,1.6 L-7,0 L-1.6,-1.6z" fill="#e1f5fe" stroke="#4fc3f7" stroke-width=".8"/>`],
];

const BG_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 100 100" preserveAspectRatio="none">
  <defs><radialGradient id="g" cx="50%" cy="40%" r="75%"><stop offset="0" stop-color="#4fc3f7"/><stop offset="1" stop-color="#1565c0"/></radialGradient></defs>
  <rect width="100" height="100" fill="url(#g)"/></svg>`;

function svgDoc(viewBox: number, body: string, px: number): string {
  const h = viewBox / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="${px}" viewBox="${-h} ${-h} ${viewBox} ${viewBox}">${body}</svg>`;
}

async function addSvg(scene: Phaser.Scene, key: string, svg: string): Promise<void> {
  if (scene.textures.exists(key)) return;
  const img = new Image();
  img.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
  await img.decode();
  scene.textures.addImage(key, img);
}

/** 텍스처 크기 배율: viewBox 1 = scale 픽셀 */
export async function generateTextures(scene: Phaser.Scene, scale: number): Promise<void> {
  await Promise.all([
    addSvg(scene, 'bg', BG_SVG),
    ...ART.map(([key, vb, body]) => addSvg(scene, key, svgDoc(vb, body, Math.round(vb * scale)))),
  ]);
}

/** 각 텍스처의 viewBox 크기. 표시 크기 = 이 값 × unit. */
export const ART_SIZE: Record<string, number> = Object.fromEntries(ART.map(([k, vb]) => [k, vb]));
