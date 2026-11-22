

import { HandCameraWidget, cameraErrorMessage } from "/api/sign/assets/js/hand-camera.js?v=20261113cpu";
import { SignInputSession } from "./sign-input.js";

export function initDictCamera({ ctx, onSearch }) {

  let camPaused = false;
  let cameraPending = false;
  function showCameraError(error) {
    document.getElementById("camStatus").textContent = cameraErrorMessage(error);
    document.getElementById("camStatus").className = "cam-status";
  }
  async function startCamera() {
    if (cameraPending) return;
    cameraPending = true;
    try {
      await cam.start();
      camPaused = false;
      document.getElementById("camPauseOverlay").classList.remove("visible");
    } catch (error) {
      if (error.name !== "AbortError") showCameraError(error);
    } finally { cameraPending = false; }
  }


  const signInput = new SignInputSession({
    apiBase: ctx,
    onUpdate: function (data) {
      var composed = data.composedText || "";
      document.getElementById("result-word").textContent = composed || "-";
      var pct = (data.holdProgress || 0) * 100;
      document.getElementById("progressFill").style.width = pct + "%";


      var conf = (data.rawConfidence || 0) * 100;
      var gaugeFill = document.getElementById("camGaugeFill");
      var gaugeLabel = document.getElementById("camGaugeLabel");
      gaugeFill.style.strokeDashoffset = String(100 - conf);
      gaugeLabel.textContent = Math.round(conf) + "%";


      var searchBtn = document.getElementById("camSearchBtn");
      var hasText = composed && composed.trim() !== "";
      if (hasText && searchBtn.disabled) {
        searchBtn.disabled = false;
        searchBtn.classList.add("cam-search-ready");
        setTimeout(function () { searchBtn.classList.remove("cam-search-ready"); }, 600);
      } else if (!hasText) {
        searchBtn.disabled = true;
      }
    },
  });


  const cam = new HandCameraWidget({
    videoEl: document.getElementById("video-word"),
    canvasEl: document.getElementById("canvas-word"),
    onError: showCameraError,
    onFrame: function (landmarks) {
      const statusEl = document.getElementById("camStatus");
      const hasHand = landmarks && landmarks.length > 0;
      if (hasHand) {
        statusEl.textContent = "✋ 인식 중";
        statusEl.className = "cam-status detected";
      } else {
        statusEl.textContent = "손을 카메라에 비춰주세요";
        statusEl.className = "cam-status not-detected";


        document.getElementById("camGaugeFill").style.strokeDashoffset = "100";
        document.getElementById("camGaugeLabel").textContent = "0%";
        document.getElementById("progressFill").style.width = "0%";
      }
      signInput.submitFrame(landmarks);
    },
  });


  document.getElementById("camToggleBtn").addEventListener("click", async () => {
    document.getElementById("result-word").textContent = "-";
    document.getElementById("progressFill").style.width = "0%";
    document.getElementById("camStatus").textContent = "카메라를 준비하는 중...";
    document.getElementById("camStatus").className = "cam-status";

    document.getElementById("camGaugeFill").style.strokeDashoffset = "100";
    document.getElementById("camGaugeLabel").textContent = "0%";


    document.getElementById("camSearchBtn").disabled = true;
    document.getElementById("camSearchBtn").classList.remove("cam-search-ready");

    try { await signInput.reset(); } catch (e) { console.error(e); }
    document.getElementById("camModal").showModal();
    await startCamera();
  });


  document.getElementById("camCloseBtn").addEventListener("click", () => {
    document.getElementById("camModal").close();
    cam.stopCamera();

    camPaused = false;
    document.getElementById("camPauseOverlay").classList.remove("visible");
  });


  document.getElementById("camResetBtn").addEventListener("click", async () => {
    try { await signInput.reset(); } catch (e) { console.error(e); }
  });


  document.getElementById("camSearchBtn").addEventListener("click", () => {
    const word = document.getElementById("result-word").textContent.trim();
    if (!word || word === "-") return;
    document.getElementById("camModal").close();
    cam.stopCamera();
    onSearch(word);
  });


  document.getElementById("camWrap").addEventListener("click", async () => {
    const overlay = document.getElementById("camPauseOverlay");
    if (!camPaused) {
      cam.stop();
      camPaused = true;
      overlay.classList.add("visible");
      document.getElementById("camStatus").textContent = "일시정지됨";
      document.getElementById("camStatus").className = "cam-status";
    } else {
      camPaused = false;
      overlay.classList.remove("visible");
      document.getElementById("camStatus").textContent = "카메라를 준비하는 중...";
      await startCamera();
    }
  });

  const tools = document.createElement("div");
  tools.style.cssText = "display:flex;gap:8px;margin:12px 0";
  const on = document.createElement("button"), off = document.createElement("button");
  for (const button of [on, off]) { button.type = "button"; button.className = "btn btn-ghost btn-sm"; }
  on.textContent = "카메라 켜기";
  off.textContent = "카메라 끄기";
  on.addEventListener("click", startCamera);
  off.addEventListener("click", () => { cam.stopCamera(); document.getElementById("camStatus").textContent = "카메라가 꺼졌습니다."; });
  tools.append(on, off);
  document.getElementById("camWrap").before(tools);
  document.getElementById("camModal").addEventListener("close", () => cam.stopCamera());
  window.addEventListener("pagehide", () => cam.stopCamera());
  return { cam, signInput };
}