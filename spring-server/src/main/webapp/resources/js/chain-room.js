import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
import { ChainSignInputSession } from "/resources/js/chain-sign-input.js";

const ctx = window.CHAIN_CTX || "";
const roomId = window.CHAIN_ROOM_ID;

let myMemberId = null;
let state = null;
let cam = null;
let signInput = null;
let timerInterval = null;

async function loadMemberId() {
  const res = await fetch(`${ctx}/notification/me`, { credentials: "same-origin" });
  if (!res.ok) return;
  const data = await res.json();
  myMemberId = data.memberId ?? null;
}

function formatRequiredChar(required, alternative) {
  if (!required) return "아무 글자나";
  return alternative ? `${required} (또는 ${alternative})` : required;
}

function memberName(memberId) {
  const m = (state.members || []).find(x => x.memberId === memberId);
  return m ? m.memberName : "?";
}

function render() {
  if (!state) return;

  document.getElementById("roomTitle").textContent = state.chainRoomName;

  const waiting = state.status === "WAITING";
  const playing = state.status === "PLAYING";
  const ended = state.status === "ENDED";

  document.getElementById("btnStart").style.display =
    waiting && state.hostMemberId === myMemberId && (state.members || []).length >= 2 ? "inline-flex" : "none";
  document.getElementById("turnBanner").style.display = playing ? "flex" : "none";
  document.getElementById("gameArea").style.display = playing ? "block" : "none";
  document.getElementById("resultArea").style.display = ended ? "block" : "none";

  document.getElementById("roomSubtitle").textContent =
    waiting ? "참가자를 기다리는 중..." : playing ? "게임 진행 중" : "게임이 종료되었습니다.";

  document.getElementById("playerList").innerHTML = (state.members || []).map(m => `
    <div class="chain-player ${state.currentTurnMemberId === m.memberId ? "turn" : ""} ${m.eliminated ? "eliminated" : ""}">
      ${state.hostMemberId === m.memberId ? '<span class="host-mark">👑</span>' : ""}
      <div style="font-weight:700;">${escapeHtml(m.memberName)}</div>
      <div class="lives">${"❤️".repeat(Math.max(0, m.lives))}${"🖤".repeat(Math.max(0, 3 - m.lives))}</div>
      <div class="score">점수 ${m.score}${m.finalRank ? ` · ${m.finalRank}위` : ""}</div>
    </div>
  `).join("");

  if (playing) {
    document.getElementById("turnPlayerName").textContent = memberName(state.currentTurnMemberId);
    document.getElementById("requiredChar").textContent = formatRequiredChar(state.requiredFirstChar, state.alternativeFirstChar);
  }

  if (ended) {
    const winner = (state.members || []).find(m => m.finalRank === 1);
    document.getElementById("winnerTitle").textContent = winner ? `🏆 우승: ${winner.memberName}` : "🏁 게임 종료";
  }

  const isMyTurn = playing && state.currentTurnMemberId === myMemberId;
  document.getElementById("btnComplete").disabled = !isMyTurn;
  if (signInput) signInput.active = isMyTurn;
  if (isMyTurn && !cam) startCamera();
}

function startTimer(deadlineEpochMillis) {
  clearInterval(timerInterval);
  const tick = () => {
    const remain = Math.max(0, Math.ceil((deadlineEpochMillis - Date.now()) / 1000));
    document.getElementById("turnTimer").textContent = `${remain}초`;
    if (remain <= 0) clearInterval(timerInterval);
  };
  tick();
  timerInterval = setInterval(tick, 250);
}

function appendLog(text, valid) {
  const log = document.getElementById("wordLog");
  const row = document.createElement("div");
  row.className = "row";
  row.innerHTML = `<span class="${valid ? "valid" : "invalid"}">${valid ? "✔" : "✘"}</span> ${text}`;
  log.prepend(row);
}

function escapeHtml(s) {
  return (s || "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
}

async function startCamera() {
  signInput = new ChainSignInputSession({
    roomId,
    onUpdate: (data) => {
      document.getElementById("composedText").textContent = data.composedText || "-";
      document.getElementById("progressFill").style.width = `${(data.holdProgress || 0) * 100}%`;
    },
  });
  signInput.active = true;

  cam = new HandCameraWidget({
    videoEl: document.getElementById("video"),
    canvasEl: document.getElementById("canvas"),
    onFrame: (landmarks) => signInput && signInput.submitFrame(landmarks),
  });
  try {
    await cam.start();
  } catch (e) {
    console.error("카메라 시작 실패", e);
  }
}

function connectWs() {
  const proto = location.protocol === "https:" ? "wss" : "ws";
  const ws = new WebSocket(`${proto}://${location.host}${ctx}/ws/playzone/chain/${roomId}`);

  ws.onmessage = (evt) => {
    const { type, payload } = JSON.parse(evt.data);
    switch (type) {
      case "STATE":
        state = payload;
        render();
        if (state.status === "PLAYING" && state.deadlineEpochMillis) startTimer(state.deadlineEpochMillis);
        break;
      case "ROOM_UPDATE":
        state = payload;
        render();
        break;
      case "GAME_START":
        fetchState().then(() => startTimer(payload.deadlineEpochMillis));
        break;
      case "TURN_START":
        if (state) {
          state.currentTurnMemberId = payload.currentTurnMemberId;
          state.requiredFirstChar = payload.requiredFirstChar;
          state.alternativeFirstChar = payload.alternativeFirstChar;
        }
        render();
        startTimer(payload.deadlineEpochMillis);
        document.getElementById("composedText").textContent = "-";
        document.getElementById("progressFill").style.width = "0%";
        break;
      case "PROGRESS":
        if (payload.memberId !== myMemberId) {
          // 다른 사람 턴 진행 상황은 로그 영역에 실시간 표시만
        }
        if (payload.deadlineEpochMillis) startTimer(payload.deadlineEpochMillis);
        break;
      case "WORD_RESULT":
        appendLog(
          `${memberName(payload.memberId)} : "${payload.attemptedWord || "(미입력)"}" ` +
          (payload.valid ? `(+${payload.scoreDelta}점)` : `(실패: ${payload.reasonCode})`),
          payload.valid
        );
        fetchState();
        break;
      case "GAME_END":
        fetchState();
        clearInterval(timerInterval);
        break;
    }
  };
  ws.onclose = () => setTimeout(connectWs, 2000);
}

function fetchState() {
  return fetch(`${ctx}/api/playzone/chain/rooms/${roomId}`, { credentials: "same-origin" })
    .then(res => res.json())
    .then(data => { state = data; render(); });
}

document.getElementById("btnStart").addEventListener("click", () => {
  fetch(`${ctx}/api/playzone/chain/rooms/${roomId}/start`, { method: "POST", credentials: "same-origin" })
    .catch(err => console.error("게임 시작 실패", err));
});

document.getElementById("btnLeave").addEventListener("click", () => {
  fetch(`${ctx}/api/playzone/chain/rooms/${roomId}/leave`, { method: "POST", credentials: "same-origin" })
    .finally(() => { location.href = `${ctx}/playzone/chain`; });
});

document.getElementById("btnComplete").addEventListener("click", () => {
  if (signInput) signInput.complete();
});

(async function init() {
  await loadMemberId();
  await fetchState();
  if (state && state.status === "WAITING") {
    await fetch(`${ctx}/api/playzone/chain/rooms/${roomId}/join`, { method: "POST", credentials: "same-origin" });
    await fetchState();
  }
  connectWs();
})();
