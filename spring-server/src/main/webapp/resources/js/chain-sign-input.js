// chain 프레임 전송 클라이언트
const FRAME_INTERVAL_MS = 150;

export class ChainSignInputSession {
  constructor({ roomId, onUpdate = null, mirror = false } = {}) {
    this.roomId = roomId;
    this.onUpdate = onUpdate;
    this.mirror = mirror;
    this._lastSentAt = 0;
    this._inFlight = false;
    this.active = false;
  }

  submitFrame(landmarks) {
    if (!landmarks || !this.active) return;
    const now = performance.now();
    if (now - this._lastSentAt < FRAME_INTERVAL_MS) return;
    if (this._inFlight) return;

    this._lastSentAt = now;
    this._inFlight = true;

    fetch(`/api/playzone/chain/rooms/${this.roomId}/frame`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "same-origin",
      body: JSON.stringify({ landmarks, mirror: this.mirror }),
    })
      .then((res) => res.json())
      .then((data) => { if (this.onUpdate) this.onUpdate(data); })
      .catch((err) => console.error("chain frame 전송 실패", err))
      .finally(() => { this._inFlight = false; });
  }

  async complete() {
    return fetch(`/api/playzone/chain/rooms/${this.roomId}/complete`, {
      method: "POST",
      credentials: "same-origin",
    });
  }
}
