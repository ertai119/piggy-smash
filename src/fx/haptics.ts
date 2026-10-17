/** 안드로이드 크롬에서 짧게 진동한다. 지원하지 않으면 아무것도 안 한다. 음소거와 무관. */
export function vibrate(ms: number): void {
  try {
    navigator.vibrate?.(ms);
  } catch {
    // 진동을 막는 환경
  }
}
