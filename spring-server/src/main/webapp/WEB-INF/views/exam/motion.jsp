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
        <a href="exam_result.html" class="btn btn-ghost btn-sm">종료</a>
      </div>
    </div>

    <div class="cam-card">
      <div class="cam-card-header">
        <h3>📷 수어 인식 시험</h3>
        <span class="badge" style="background:rgba(124,58,237,.1); color:#5b21b6; padding:6px 14px; font-size:13px; font-weight:700;" id="cam-q-badge">문제 1</span>
      </div>
      <div class="cam-target-banner">
        <div class="cam-target-label">아래 단어를 수어로 표현하세요</div>
        <div class="cam-target-word" id="cam-target-word">🚑 구급차</div>
      </div>
      <div class="cam-preview-area">
        <span>✋</span>
        <p>카메라를 켜고 수어를 표현하세요</p>
      </div>
      <div class="cam-result-row">
        <div class="cam-result-main">
          <div class="cam-rlabel">AI 인식 결과</div>
          <div class="cam-rword" id="cam-result-word">— 대기 중 —</div>
          <div class="cam-rconf" id="cam-result-conf">카메라를 시작하면 실시간으로 인식합니다.</div>
        </div>
        <span class="badge badge-primary" id="cam-acc-badge" style="font-size:14px; padding:8px 16px; display:none;"></span>
      </div>
      <div class="cam-controls-row">
        <button class="btn btn-primary" style="flex:1; justify-content:center; font-size:14px;" onclick="runCamRecognition()">📷 카메라 시작</button>
        <button class="btn btn-ghost btn-sm" onclick="resetCamResult()">초기화</button>
      </div>
      <div class="cam-submit-row">
        <button class="btn btn-primary" style="width:100%; justify-content:center;" onclick="submitCam()">✅ 이 동작으로 제출</button>
      </div>
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script>
const totalCount = 10;
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
  document.getElementById('cam-target-word').textContent = `${c.emoji} ${c.word}`;
  resetCamResult();
}

function resetCamResult() {
  document.getElementById('cam-result-word').textContent = '— 대기 중 —';
  document.getElementById('cam-result-conf').textContent = '카메라를 시작하면 실시간으로 인식합니다.';
  document.getElementById('cam-acc-badge').style.display = 'none';
  camResultReady = false;
}

function runCamRecognition() {
  const target = camBank[camIndex % camBank.length];
  currentCamCorrect = Math.random() < 0.8;
  const conf = Math.floor(70 + Math.random() * 29);
  document.getElementById('cam-result-word').textContent = currentCamCorrect ? target.word : '인식 실패';
  document.getElementById('cam-result-conf').textContent = `신뢰도 ${conf}%`;
  const badge = document.getElementById('cam-acc-badge');
  badge.style.display = 'inline-block';
  badge.textContent = conf + '%';
  camConfidences.push(conf);
  camResultReady = true;
}

function updateCamProgress(cur, total) {
  const pct = Math.round((cur / total) * 100);
  document.getElementById('cam-prog-text').textContent = `수어 인식 ${cur} / ${total}`;
  document.getElementById('cam-prog-pct').textContent = pct + '%';
  document.getElementById('cam-prog-fill').style.width = pct + '%';
  document.getElementById('cam-q-badge').textContent = `문제 ${cur}`;
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
  location.href = 'exam_result.html';
}
</script>
</body>
</html>
