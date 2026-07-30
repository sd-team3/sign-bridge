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
            <video id="video-word" autoplay playsinline muted></video>
            <canvas id="canvas-word"></canvas>
          </div>
        </div>

        <div class="cam-right">
          <div class="cam-result-panel">
            <div class="cam-rlabel">AI 인식 결과</div>
            <div class="cam-rword" id="result-word">-</div>
            <div class="cam-rconf">손모양을 1.2초간 유지하면 입력돼요.</div>
            <div class="progress-bar" style="height:6px; background:var(--surface2); border-radius:100px; overflow:hidden; margin-top:8px;">
              <div id="progressFill" style="height:100%; background:var(--primary); width:0%; transition:width .1s;"></div>
            </div>
          </div>
          <div class="cam-right-controls">
            <button class="btn btn-primary cam-submit-btn" onclick="submitCam()">✅ 정답 제출</button>
            <button class="btn btn-ghost btn-sm" onclick="resetCamResult()">초기화</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script type="module" src="/resources/js/word-camera.js"></script>

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

loadCamQuestion(0);
updateCamProgress(1, totalCount);
startTimer('cam-timer', 600, finishExam);

function loadCamQuestion(idx) {
  const c = camBank[idx % camBank.length];
  document.getElementById('cam-target-word').textContent = `\${c.emoji} \${c.word}`;
  resetCamResult();
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

function resetCamResult() {
  fetch('/api/sign/reset', { method: 'POST', credentials: 'same-origin' })
    .then(() => {
      document.getElementById('result-word').textContent = '-';
      document.getElementById('progressFill').style.width = '0%';
    })
    .catch(err => console.error('세션 초기화 실패', err));
}

function submitCam() {
  const composed = document.getElementById('result-word').textContent.trim();
  if (!composed || composed === '-') return;

  const c = camBank[camIndex % camBank.length];
  const isCorrect = composed === c.word;

  if (isCorrect) {
    camCorrectCount++;
    document.getElementById('cam-correct').textContent = camCorrectCount;
  } else {
    camWrongCount++;
    document.getElementById('cam-wrong').textContent = camWrongCount;
    wrongList.push({ no: ++wrongNo, word: c.word, type: 'cam', userAnswer: composed, correctAnswer: c.word });
  }

  camIndex++;
  if (camIndex >= totalCount) { finishExam(); return; }
  loadCamQuestion(camIndex); // 내부에서 resetCamResult() 호출됨
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
