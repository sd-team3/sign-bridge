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
const CLIENT_SESSION_STORAGE_KEY = "signbridge_client_session_id";

/** 로컬스토리지에 저장된 클라이언트 세션 id를 가져오거나, 없으면 새로 만들어서 저장한다.
 *  recognition_confirm_log.client_session_id 컬럼용 - 로그인 여부와 무관하게
 *  "이 브라우저가 남긴 로그들"을 하나로 묶어서 추적하기 위한 값이다. */
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
    this.memberId = null; // /notification/me 응답으로 채워짐 (비로그인이면 null 유지)
    this._lastSentAt = 0;
    this._inFlight = false;

    this._loadMemberId();
  }

  /** /notification/me를 호출해서 로그인한 회원 번호를 받아온다.
   *  ⚠️ 응답 필드명이 { memberId: ... } 라고 가정했음 - 실제 응답 형태가 다르면
   *  아래 data.memberId 부분만 맞게 고치면 됨. 비로그인/실패 시 memberId는 null로 유지. */
  async _loadMemberId() {
    try {
      const res = await fetch(`${this.apiBase}/notification/me`, { credentials: "same-origin" });
      if (!res.ok) return; // 비로그인 등으로 실패하면 memberId null 유지
      const data = await res.json();
      this.memberId = data.memberId ?? null;
    } catch (err) {
      console.warn("/notification/me 조회 실패 (비로그인이면 정상):", err);
    }
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
