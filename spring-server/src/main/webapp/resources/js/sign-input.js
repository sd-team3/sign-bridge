

























const FRAME_INTERVAL_MS = 150;
const CLIENT_SESSION_STORAGE_KEY = "signbridge_client_session_id";




function getOrCreateClientSessionId() {
  let id = localStorage.getItem(CLIENT_SESSION_STORAGE_KEY);
  if (!id) {
    id = (crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(36).slice(2)}`);
    localStorage.setItem(CLIENT_SESSION_STORAGE_KEY, id);
  }
  return id;
}

export class SignInputSession {
  constructor({ apiBase = "", onUpdate = null, mirror = false } = {}) {
    this.apiBase = apiBase.replace(/\/$/, "");
    this.onUpdate = onUpdate;
    this.mirror = mirror;
    this.clientSessionId = getOrCreateClientSessionId();
    this.memberId = null;
    this._lastSentAt = 0;
    this._inFlight = false;

    this._loadMemberId();
  }




  async _loadMemberId() {
    try {
      const res = await fetch(`${this.apiBase}/notification/me`, { credentials: "same-origin" });
      if (!res.ok) return;
      const data = await res.json();
      this.memberId = data.memberId ?? null;
    } catch (err) {
      console.warn("/notification/me 조회 실패 (비로그인이면 정상):", err);
    }
  }


  submitFrame(landmarks) {
    if (!landmarks) return;

    const now = performance.now();
    if (now - this._lastSentAt < FRAME_INTERVAL_MS) return;
    if (this._inFlight) return;

    this._lastSentAt = now;
    this._inFlight = true;

    fetch(`${this.apiBase}/api/sign/frame`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "same-origin",
      body: JSON.stringify({
        landmarks,
        mirror: this.mirror,
        clientSessionId: this.clientSessionId,
        memberId: this.memberId,
      }),
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


  async insertSpace() {
    const res = await fetch(`${this.apiBase}/api/sign/space`, {
      method: "POST",
      credentials: "same-origin",
    });
    const data = await res.json();
    if (this.onUpdate) this.onUpdate(data);
    return data;
  }


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
