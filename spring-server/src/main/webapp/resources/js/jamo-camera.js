import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
import { JamoApiClient } from "http://localhost:8000/static/js/api-client.js";

const api = new JamoApiClient("http://localhost:8000");

window.jamoCamStarted = false;
window.currentJamoChar = null;

const cam = new HandCameraWidget({
  videoEl: document.getElementById("video"),
  canvasEl: document.getElementById("canvas"),
  onFrame: async (landmarks) => {
    const resultEl = document.getElementById("result");
    if (!landmarks) {
      resultEl.textContent = '';
      resultEl.style.color = '';
      return;
    }
    const result = await api.predict(landmarks, false);

    if (!result || !result.label) {
      resultEl.textContent = '';
      resultEl.style.color = '';
      return;
    }

    if (!window.currentJamoChar) {
      resultEl.textContent = result.label;
      resultEl.style.color = '';
      return;
    }

    const isCorrect = result.label === window.currentJamoChar;
    resultEl.textContent = isCorrect
      ? '✅ 정답! (' + result.label + ')'
      : '인식: ' + result.label;
    resultEl.style.color = isCorrect ? '#2D9B6F' : '#D85A30';
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