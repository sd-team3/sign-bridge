// dict-camera.js
// dict.jsp의 수어 인식 모달(카메라로 손모양 인식해서 단어 검색) 로직
import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
import { SignInputSession } from "./sign-input.js";

export function initDictCamera({ ctx, onSearch }) {
  // 카메라 일시정지 여부 (영상 클릭시 토글)
  let camPaused = false;

  // 자,모 조합 알고리즘
  const signInput = new SignInputSession({
    apiBase: ctx,
    onUpdate: function (data) {
      var composed = data.composedText || "";
      document.getElementById("result-word").textContent = composed || "-";
      var pct = (data.holdProgress || 0) * 100;
      document.getElementById("progressFill").style.width = pct + "%";

      // 확신도 게이지 갱신
      var conf = (data.rawConfidence || 0) * 100;
      var gaugeFill = document.getElementById("camGaugeFill");
      var gaugeLabel = document.getElementById("camGaugeLabel");
      gaugeFill.style.strokeDashoffset = String(100 - conf);
      gaugeLabel.textContent = Math.round(conf) + "%";

      // 조합된 글자가 생기면 검색 버튼 활성화 + 펄스 애니메이션
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

  // 카메라 손 추출
  const cam = new HandCameraWidget({
    videoEl: document.getElementById("video-word"),
    canvasEl: document.getElementById("canvas-word"),
    onFrame: function (landmarks) {
      const statusEl = document.getElementById("camStatus");
      const hasHand = landmarks && landmarks.length > 0;
      if (hasHand) {
        statusEl.textContent = "✋ 인식 중";
        statusEl.className = "cam-status detected";
      } else {
        statusEl.textContent = "손을 카메라에 비춰주세요";
        statusEl.className = "cam-status not-detected";

        // 손 없으면 게이지 0으로
        document.getElementById("camGaugeFill").style.strokeDashoffset = "100";
        document.getElementById("camGaugeLabel").textContent = "0%";
        document.getElementById("progressFill").style.width = "0%";
      }
      signInput.submitFrame(landmarks);
    },
  });

  // 캠 클릭시 이전세션 초기화 후 카메라 인식 시작
  document.getElementById("camToggleBtn").addEventListener("click", async () => {
    document.getElementById("result-word").textContent = "-";
    document.getElementById("progressFill").style.width = "0%";
    document.getElementById("camStatus").textContent = "카메라를 준비하는 중...";
    document.getElementById("camStatus").className = "cam-status";

    document.getElementById("camGaugeFill").style.strokeDashoffset = "100";
    document.getElementById("camGaugeLabel").textContent = "0%";

    // 검색 버튼도 다시 비활성화
    document.getElementById("camSearchBtn").disabled = true;
    document.getElementById("camSearchBtn").classList.remove("cam-search-ready");

    try { await signInput.reset(); } catch (e) { console.error(e); }
    document.getElementById("camModal").showModal();
    await cam.start();
    camPaused = false;
    document.getElementById("camPauseOverlay").classList.remove("visible");
  });

  // 닫기 ... 카메라 스트림 정지
  document.getElementById("camCloseBtn").addEventListener("click", () => {
    document.getElementById("camModal").close();
    cam.stop();
    // 일시정지 상태였다면 다음에 다시 열 때 정상적으로 보이도록 초기화
    camPaused = false;
    document.getElementById("camPauseOverlay").classList.remove("visible");
  });

  // 세션만 리셋(카메라 그대로)
  document.getElementById("camResetBtn").addEventListener("click", async () => {
    try { await signInput.reset(); } catch (e) { console.error(e); }
  });

  // 일반검색과 로직동일
  document.getElementById("camSearchBtn").addEventListener("click", () => {
    const word = document.getElementById("result-word").textContent.trim();
    if (!word || word === "-") return;
    document.getElementById("camModal").close();
    cam.stop();
    onSearch(word);
  });

  // 카메라 영상 클릭시 정지/재개 토글
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
      await cam.start();
    }
  });

  return { cam, signInput };
}