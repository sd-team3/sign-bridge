// sign-input.js
// ─────────────────────────────────────────────────────────
// hand-camera.js(파이썬 서버가 서빙)로 뽑은 landmark를,
// 매 프레임 Python으로 직접 보내는 대신 Spring의 /api/sign/frame으로 보낸다.
// Spring이 내부적으로 Python 호출 + 1.2초 유지 판정 + 자모 조합까지 다 처리하고
// "지금까지 조합된 텍스트"를 그때그때 돌려준다.
//
// 사용 예 (JSP 안에서):
//   import { HandCameraWidget } from "http://<python-host>:8000/static/js/hand-camera.js";
//   import { SignInputSession } from "/resources/js/sign-input.js";
//
//   const signInput = new SignInputSession({
//     onUpdate: ({ composedText, holdProgress, rawLabel, confirmedChar }) => {
//       document.getElementById("result").textContent = composedText;
//       document.getElementById("progress").style.width = `${holdProgress * 100}%`;
//     },
//   });
//
//   const cam = new HandCameraWidget({
//     videoEl: document.getElementById("video"),
//     canvasEl: document.getElementById("canvas"),
//     onFrame: (landmarks) => signInput.submitFrame(landmarks),
//   });
//   await cam.start();
// ─────────────────────────────────────────────────────────

const FRAME_INTERVAL_MS = 150; // 0.15초마다 서버에 전송 (그보다 자주 오는 프레임은 버림)

export class SignInputSession {
  constructor({ apiBase = "", onUpdate = null, mirror = false } = {}) {
    this.apiBase = apiBase.replace(/\/$/, "");
    this.onUpdate = onUpdate;
    this.mirror = mirror;
    this._lastSentAt = 0;
    this._inFlight = false;
  }

  /** hand-camera.js의 onFrame 콜백에 그대로 연결. landmarks가 null이면 아무것도 안 보냄. */
  submitFrame(landmarks) {
    if (!landmarks) return;

    const now = performance.now();
    if (now - this._lastSentAt < FRAME_INTERVAL_MS) return; // 스로틀링
    if (this._inFlight) return; // 이전 요청 응답 오기 전에 또 보내지 않음 (요청 밀림 방지)

    this._lastSentAt = now;
    this._inFlight = true;

    fetch(`${this.apiBase}/api/sign/frame`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "same-origin", // 세션 쿠키 유지 (조합 상태가 세션에 저장되므로 필수)
      body: JSON.stringify({ landmarks, mirror: this.mirror }),
    })
      .then((res) => res.json())
      .then((data) => {
        if (this.onUpdate) this.onUpdate(data);
      })
      .catch((err) => console.error("sign frame 전송 실패", err))
      .finally(() => {
        this._inFlight = false;
      });
  }

  /** 지금까지 조합 중인 걸 확정하고 띄어쓰기 (다음 단어로 넘어갈 때). */
  async insertSpace() {
    const res = await fetch(`${this.apiBase}/api/sign/space`, {
      method: "POST",
      credentials: "same-origin",
    });
    const data = await res.json();
    if (this.onUpdate) this.onUpdate(data);
    return data;
  }

  /** 전체 초기화 (새 단어/문장 시작). */
  async reset() {
    const res = await fetch(`${this.apiBase}/api/sign/reset`, {
      method: "POST",
      credentials: "same-origin",
    });
    const data = await res.json();
    if (this.onUpdate) this.onUpdate(data);
    return data;
  }
}
