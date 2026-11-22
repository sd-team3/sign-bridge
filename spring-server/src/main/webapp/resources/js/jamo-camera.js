import { HandCameraWidget, cameraErrorMessage } from "/api/sign/assets/js/hand-camera.js?v=20261113cpu";
import { JamoApiClient } from "/api/sign/assets/js/api-client.js";

const api = new JamoApiClient("/api/sign/jamo");

window.jamoCamStarted = false;
window.currentJamoChar = null;

const COACH_INTERVAL_MS = 3000;
const STABLE_HOLD_MS = 1200;
let lastCoachAt = 0;
let coachInFlight = false;
let coachTrackedJamo = null;

let holdLabel = null;
let holdStartAt = null;

const TIP_STYLES = {
  mismatch: { bg: "#FDEBEC", border: "#F3B7BA", color: "#9A2F32", icon: "⚠️" },
  advice: { bg: "#FFF7E6", border: "#FFD57E", color: "#8A5A00", icon: "💡" },
  perfect: { bg: "#EAF6EE", border: "#A9DFBF", color: "#1E6B3C", icon: "✨" },
};

function hideCoachTip() {
  const tipEl = document.getElementById("coachTip");
  if (tipEl) tipEl.style.display = "none";
}

function showCoachTip(text, kind) {
  const tipEl = document.getElementById("coachTip");
  if (!tipEl) return;
  const style = TIP_STYLES[kind] || TIP_STYLES.advice;
  tipEl.style.background = style.bg;
  tipEl.style.borderColor = style.border;
  tipEl.style.color = style.color;
  tipEl.textContent = style.icon + " " + text;
  tipEl.style.display = "block";
}

function resetCoachThrottleIfJamoChanged() {
  if (window.currentJamoChar !== coachTrackedJamo) {
    coachTrackedJamo = window.currentJamoChar;
    lastCoachAt = 0;
  }
}

function isHandShapeStable(label) {
  const now = Date.now();
  if (label !== holdLabel) {
    holdLabel = label;
    holdStartAt = now;
    return false;
  }
  return now - holdStartAt >= STABLE_HOLD_MS;
}

async function maybeFetchCoachTip(landmarks, targetLabel, predictedLabel, predictedConfidence) {
  resetCoachThrottleIfJamoChanged();
  const now = Date.now();
  if (coachInFlight || now - lastCoachAt < COACH_INTERVAL_MS) return;
  coachInFlight = true;
  lastCoachAt = now;
  try {
    const res = await api.coach(landmarks, targetLabel, predictedLabel, predictedConfidence, false);
    if (res && res.tip) {
      showCoachTip(res.tip, res.kind);
    }
  } catch (err) {
    console.error("코칭 팁 요청 실패:", err);
  } finally {
    coachInFlight = false;
  }
}

function resetHold() {
  holdLabel = null;
  holdStartAt = null;
}

const cam = new HandCameraWidget({
  videoEl: document.getElementById("video"),
  canvasEl: document.getElementById("canvas"),
  onError: showCameraError,
  onFrame: async (landmarks) => {
    const resultEl = document.getElementById("result");
    if (!landmarks) {
      resultEl.textContent = "";
      resultEl.style.color = "";
      hideCoachTip();
      resetHold();
      return;
    }
    const result = await api.predict(landmarks, false);

    if (!result || !result.label) {
      resultEl.textContent = "";
      resultEl.style.color = "";
      hideCoachTip();
      resetHold();
      return;
    }

    if (!window.currentJamoChar) {
      resultEl.textContent = result.label;
      resultEl.style.color = "";
      hideCoachTip();
      resetHold();
      return;
    }

    const isCorrect = result.label === window.currentJamoChar;
    resultEl.textContent = isCorrect
      ? "✅ 정답! (" + result.label + ")"
      : "인식: " + result.label;
    resultEl.style.color = isCorrect ? "#2D9B6F" : "#D85A30";

    if (isHandShapeStable(result.label)) {
      maybeFetchCoachTip(landmarks, window.currentJamoChar, result.label, result.confidence);
    }
  },
});

let started = false;
let pending = false;
let cameraAttempt = 0;
function cameraControls() {
  document.getElementById("jd-camera-on").disabled = started || pending;
  document.getElementById("jd-camera-off").disabled = !started && !pending;
}
function showCameraError(error) {
  window.stopJamoCam();
  document.getElementById("jd-camera-status").textContent = cameraErrorMessage(error);
}
document.getElementById("jd-camera-on").addEventListener("click", async () => {
  if (started || pending) return;
  const attempt = ++cameraAttempt;
  pending = true;
  cameraControls();
  document.getElementById("jd-camera-status").textContent = "카메라와 손 인식을 준비하고 있어요…";
  try {
    await cam.start();
    if (attempt !== cameraAttempt) return;
    started = true;
    window.jamoCamStarted = true;
    document.getElementById("result").textContent = "-";
    document.getElementById("jd-camera-status").textContent = "카메라가 준비됐어요. 손을 화면에 보여 주세요.";
  } catch (error) {
    if (attempt === cameraAttempt && error.name !== "AbortError") showCameraError(error);
  } finally { if (attempt === cameraAttempt) { pending = false; cameraControls(); } }
});
window.stopJamoCam = () => {
  cameraAttempt++;
  cam.stopCamera();
  started = false;
  pending = false;
  window.jamoCamStarted = false;
  resetHold();
  hideCoachTip();
  document.getElementById("result").textContent = "카메라 켜기를 눌러 주세요";
  document.getElementById("jd-camera-status").textContent = "카메라가 꺼졌습니다.";
  cameraControls();
};
document.getElementById("jd-camera-off").addEventListener("click", window.stopJamoCam);
window.addEventListener("pagehide", window.stopJamoCam);
