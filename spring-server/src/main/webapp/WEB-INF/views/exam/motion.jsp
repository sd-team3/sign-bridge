<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 수어 시험 진행 (카메라 인식)</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="exam-header">
      <div class="exam-progress-wrap">
        <div class="exam-progress-label">
          <span id="cam-prog-text">수어 인식 1 / 10</span>
          <span id="cam-prog-pct">10%</span>
        </div>
        <div class="exam-progress-bar">
          <div class="exam-progress-fill" id="cam-prog-fill" style="width:10%"></div>
        </div>
      </div>
      <div class="timer-badge">
        <div class="timer-num" id="cam-timer">10:00</div>
        <div class="timer-label">남은 시간</div>
      </div>
      <div style="display:flex; gap:12px; align-items:center;">
        <span style="font-size:14px; font-weight:700; color:var(--text-sub);">정답 <span id="cam-correct" style="color:var(--primary);">0</span> / 오답 <span id="cam-wrong" style="color:var(--danger);">0</span></span>
        <a href="/exam/result" class="btn btn-ghost btn-sm">종료</a>
      </div>
    </div>

    <div class="cam-card">
      <div class="cam-card-header">
        <h3>📷 수어 인식 시험</h3>
        <span class="badge" style="background:rgba(124,58,237,.1); color:#5b21b6; padding:6px 14px; font-size:13px; font-weight:700;" id="cam-q-badge">문제 1</span>
      </div>

      <div class="cam-main-grid">
        <div class="cam-left">
          <div class="cam-target-banner">
            <div class="cam-target-label">아래 단어를 수어로 표현하세요</div>
            <div class="cam-target-word" id="cam-target-word">🚑 구급차</div>
          </div>
          <div class="cam-wrap-exam">
            <video id="video" autoplay playsinline muted></video>
            <canvas id="canvas"></canvas>
          </div>
        </div>

        <div class="cam-right">
          <div class="cam-result-panel">
            <div class="cam-rlabel">AI 인식 결과</div>
            <div class="cam-rword" id="cam-result-word">— 대기 중 —</div>
            <div class="cam-rconf" id="cam-result-conf">카메라를 시작하면 실시간으로 인식합니다.</div>
            <span class="badge badge-primary" id="cam-acc-badge" style="font-size:14px; padding:8px 16px; display:none; margin-top:10px;"></span>
          </div>

          <div class="cam-right-controls">
            <button class="btn btn-primary" style="justify-content:center; font-size:14px;" onclick="runCamRecognition()">📷 카메라 시작</button>
            <button class="btn btn-ghost btn-sm" onclick="resetCamResult()">초기화</button>
          </div>

          <button class="btn btn-primary cam-submit-btn" onclick="submitCam()">✅ 이 동작으로 제출</button>
        </div>
      </div>
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script type="module">
  import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
  import { JamoApiClient } from "http://localhost:8000/static/js/api-client.js";

  const api = new JamoApiClient("http://localhost:8000");

  const cam = new HandCameraWidget({
    videoEl: document.getElementById("video"),
    canvasEl: document.getElementById("canvas"),
    onFrame: async (landmarks) => {
      if (!landmarks) return;
      const result = await api.predict(landmarks, false);
      document.getElementById("result").textContent = result.label;
    },
  });

  await cam.start();
</script>

<script>
const params = new URLSearchParams(location.search);
const examMode = params.get('mode');
const countParam = parseInt(params.get('count'), 10);
const total = isNaN(countParam) ? 10 : countParam;
const totalCount = examMode === 'both' ? Math.ceil(total / 2) : total;
const camBank = [
  { word:'구급차', emoji:'🚑', category:'비상 어휘' },
  { word:'소방서', emoji:'🚒', category:'비상 어휘' },
  { word:'병원', emoji:'🏥', category:'기초 어휘' },
  { word:'경찰서', emoji:'🚓', category:'비상 어휘' }
];

let timerInterval = null;
let camIndex = 0;
let camCorrectCount = 0, camWrongCount = 0;
let camConfidences = [];
let wrongList = [];
let wrongNo = 0;
let camResultReady = false;
let currentCamCorrect = false;

loadCamQuestion(0);
updateCamProgress(1, totalCount);
startTimer('cam-timer', 600, finishExam);

function loadCamQuestion(idx) {
  const c = camBank[idx % camBank.length];
  document.getElementById('cam-target-word').textContent = `\${c.emoji} \${c.word}`;
  resetCamResult();
}

function resetCamResult() {
  document.getElementById('cam-result-word').textContent = '— 대기 중 —';
  document.getElementById('cam-result-conf').textContent = '카메라를 시작하면 실시간으로 인식합니다.';
  document.getElementById('cam-acc-badge').style.display = 'none';
  camResultReady = false;
}

function updateCamProgress(cur, total) {
  const pct = Math.round((cur / total) * 100);
  document.getElementById('cam-prog-text').textContent = `수어 인식 \${cur} / \${total}`;
  document.getElementById('cam-prog-pct').textContent = pct + '%';
  document.getElementById('cam-prog-fill').style.width = pct + '%';
  document.getElementById('cam-q-badge').textContent = `문제 \${cur}`;
}

function startTimer(elemId, seconds, onEnd) {
  clearInterval(timerInterval);
  let s = seconds;
  const el = document.getElementById(elemId);
  const tick = () => {
    const m = Math.floor(s / 60), sec = s % 60;
    el.textContent = `\${String(m).padStart(2,'0')}:\${String(sec).padStart(2,'0')}`;
    el.style.color = s <= 60 ? 'var(--danger)' : 'var(--primary)';
    if (s <= 0) { clearInterval(timerInterval); onEnd(); }
    s--;
  };
  tick();
  timerInterval = setInterval(tick, 1000);
}

function submitCam() {
  if (!camResultReady) return;
  const c = camBank[camIndex % camBank.length];
  if (currentCamCorrect) {
    camCorrectCount++;
    document.getElementById('cam-correct').textContent = camCorrectCount;
  } else {
    camWrongCount++;
    document.getElementById('cam-wrong').textContent = camWrongCount;
    wrongList.push({ no: ++wrongNo, word: c.word, type: 'cam', category: c.category, userAnswer: '인식 실패', correctAnswer: c.word });
  }
  camIndex++;
  if (camIndex >= totalCount) {
    finishExam();
    return;
  }
  loadCamQuestion(camIndex);
  updateCamProgress(camIndex + 1, totalCount);
}

function finishExam() {
  clearInterval(timerInterval);
  // 채점 결과를 결과 페이지로 넘기는 로직은 추후 연결 예정
  location.href = '/exam/result';
}
</script>
</body>
</html>
