import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
import { JamoApiClient } from "http://localhost:8000/static/js/api-client.js";

const api = new JamoApiClient("http://localhost:8000");

window.jamoCamStarted = false;
window.currentJamoChar = null;

const COACH_INTERVAL_MS = 6000;
const STABLE_HOLD_MS = 1200;
let lastCoachAt = 0;
let coachInFlight = false;
let coachTrackedJamo = null;

let holdLabel = null;
let holdStartAt = null;

function hideCoachTip() {
  const tipEl = document.getElementById("coachTip");
  if (tipEl) tipEl.style.display = 'none';
}

function showCoachTip(text) {
  const tipEl = document.getElementById("coachTip");
  if (!tipEl) return;
  tipEl.textContent = '💡 ' + text;
  tipEl.style.display = 'block';
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

async function maybeFetchCoachTip(landmarks, label) {
  resetCoachThrottleIfJamoChanged();
  const now = Date.now();
  if (coachInFlight || now - lastCoachAt < COACH_INTERVAL_MS) return;
  coachInFlight = true;
  lastCoachAt = now;
  try {
    const res = await api.coach(landmarks, label, false);
    if (res && res.tip) {
      showCoachTip(res.tip);
    } else {
      hideCoachTip();
    }
  } catch (err) {
    console.error('코칭 팁 요청 실패:', err);
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
  onFrame: async (landmarks) => {
    const resultEl = document.getElementById("result");
    if (!landmarks) {
      resultEl.textContent = '';
      resultEl.style.color = '';
      hideCoachTip();
      resetHold();
      return;
    }
    const result = await api.predict(landmarks, false);

    if (!result || !result.label) {
      resultEl.textContent = '';
      resultEl.style.color = '';
      hideCoachTip();
      resetHold();
      return;
    }

    if (!window.currentJamoChar) {
      resultEl.textContent = result.label;
      resultEl.style.color = '';
      hideCoachTip();
      resetHold();
      return;
    }

    const isCorrect = result.label === window.currentJamoChar;
    resultEl.textContent = isCorrect
      ? '✅ 정답! (' + result.label + ')'
      : '인식: ' + result.label;
    resultEl.style.color = isCorrect ? '#2D9B6F' : '#D85A30';

    if (isCorrect) {
      if (isHandShapeStable(result.label)) {
        maybeFetchCoachTip(landmarks, result.label);
      }
    } else {
      hideCoachTip();
      resetHold();
    }
  },
});

let started = false;

document.getElementById("jdCam").addEventListener("click", async () => {
  if (started) return;
  started = true;
  window.jamoCamStarted = true;

  const resultEl = document.getElementById("result");
  resultEl.style.cursor = 'default';
  resultEl.textContent = '-';

  try {
    await cam.start();
  } catch (error) {
    console.error('카메라 시작 실패: ', error);
    started = false;
    window.jamoCamStarted = false;
    resultEl.textContent = '카메라 연결 실패';
    resultEl.style.cursor = 'pointer';
  }
});

window.stopJamoCam = () => {
  cam.stopCamera();
  started = false;
  window.jamoCamStarted = false;
};

window.addEventListener('beforeunload', () => {
  window.stopJamoCam?.();
});
