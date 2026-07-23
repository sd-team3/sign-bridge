<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 수어 시험 진행 (퀴즈)</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="exam-header">
      <div class="exam-progress-wrap">
        <div class="exam-progress-label">
          <span id="quiz-prog-text">퀴즈 1 / 10</span>
          <span id="quiz-prog-pct">10%</span>
        </div>
        <div class="exam-progress-bar">
          <div class="exam-progress-fill" id="quiz-prog-fill" style="width:10%"></div>
        </div>
      </div>
      <div class="timer-badge">
        <div class="timer-num" id="quiz-timer">10:00</div>
        <div class="timer-label">남은 시간</div>
      </div>
      <div style="display:flex; gap:12px; align-items:center;">
        <span style="font-size:14px; font-weight:700; color:var(--text-sub);">정답 <span id="quiz-correct" style="color:var(--primary);">0</span> / 오답 <span id="quiz-wrong" style="color:var(--danger);">0</span></span>
        <a href="javascript:void(0)" onclick="endQuizPhase()" class="btn btn-ghost btn-sm">종료</a>
      </div>
    </div>

    <div class="quiz-card">
      <div class="quiz-card-header">
        <h3 id="quiz-type-label">🖼️ 객관식</h3>
        <span class="badge badge-primary" id="quiz-q-badge">문제 1</span>
      </div>
      <div class="quiz-body">
        <div class="video-box">
          <div class="play-btn">▶</div>
          <p>수어 동작 영상 — 클릭해서 재생</p>
        </div>

        <div id="multiple-choice-area">
          <p style="font-size:14px; font-weight:700; color:var(--text-sub); margin-bottom:14px;">이 수어가 나타내는 단어는 무엇인가요?</p>
          <div class="choices" id="choices-list"></div>
        </div>

        <div id="subjective-area" style="display:none;">
          <p style="font-size:14px; font-weight:700; color:var(--text-sub); margin-bottom:14px;">이 수어가 나타내는 단어를 직접 입력하세요.</p>
          <div class="subjective-input-wrap">
            <input type="text" class="subjective-input" id="subjective-input" placeholder="단어 입력" autocomplete="off">
            <div class="subjective-hint">정확한 단어를 입력하면 자동으로 채점됩니다.</div>
          </div>
          <button class="btn btn-primary" style="width:100%; justify-content:center;" onclick="submitSubjective()">✅ 제출</button>
        </div>

        <div class="feedback-box" id="quiz-feedback"></div>

        <div class="quiz-nav">
          <div style="display:flex; gap:8px;">
            <button class="btn btn-ghost btn-sm" id="toggle-type-btn" onclick="toggleQuizType()">주관식으로 전환</button>
          </div>
          <button class="btn btn-primary btn-sm" id="quiz-next-btn" onclick="nextQuizQuestion()" style="display:none;">다음 문제 →</button>
        </div>
      </div>
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script>
const params = new URLSearchParams(location.search);
const examMode = params.get('mode');
const countParam = parseInt(params.get('count'), 10);
const total = isNaN(countParam) ? 10 : countParam;
const totalCount = examMode === 'both' ? Math.ceil(total / 2) : total;
const quizBank = [
  { word:'병원', choices:['사과','병원','자동차','감사합니다'], correct:1, category:'기초 어휘' },
  { word:'지진', choices:['지진','태풍','화재','대피'], correct:0, category:'비상 어휘' },
  { word:'구급차', choices:['소방차','경찰차','구급차','버스'], correct:2, category:'비상 어휘' },
  { word:'사랑해요', choices:['고마워요','미안해요','사랑해요','안녕하세요'], correct:2, category:'기초 어휘' }
];

let timerInterval = null;
let quizAnswered = false;
let isSubjective = false;
let quizIndex = 0;
let quizCorrectCount = 0, quizWrongCount = 0;
let wrongList = [];
let wrongNo = 0;

loadQuizQuestion(0);
updateQuizProgress(1, totalCount);
startTimer('quiz-timer', 600, endQuizPhase);

function loadQuizQuestion(idx) {
  const q = quizBank[idx % quizBank.length];
  const list = document.getElementById('choices-list');
  const labels = ['①','②','③','④'];
  list.innerHTML = q.choices.map((c, i) =>
    `<button class="choice-btn" onclick="selectChoice(this, \${i})"><span class="choice-label">\${labels[i]}</span> \${c}</button>`
  ).join('');
  document.getElementById('subjective-input').value = '';
  document.getElementById('quiz-feedback').className = 'feedback-box';
  document.getElementById('quiz-next-btn').style.display = 'none';
  quizAnswered = false;
}

function updateQuizProgress(cur, total) {
  const pct = Math.round((cur / total) * 100);
  document.getElementById('quiz-prog-text').textContent = `퀴즈 \${cur} / \${total}`;
  document.getElementById('quiz-prog-pct').textContent = pct + '%';
  document.getElementById('quiz-prog-fill').style.width = pct + '%';
  document.getElementById('quiz-q-badge').textContent = `문제 ${cur}`;
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

function toggleQuizType() {
  isSubjective = !isSubjective;
  document.getElementById('multiple-choice-area').style.display = isSubjective ? 'none' : 'block';
  document.getElementById('subjective-area').style.display = isSubjective ? 'block' : 'none';
  document.getElementById('toggle-type-btn').textContent = isSubjective ? '객관식으로 전환' : '주관식으로 전환';
  document.getElementById('quiz-type-label').textContent = isSubjective ? '✏️ 주관식' : '🖼️ 객관식';
  document.getElementById('quiz-feedback').className = 'feedback-box';
  document.getElementById('quiz-next-btn').style.display = 'none';
  quizAnswered = false;
}

function selectChoice(btn, idx) {
  if (quizAnswered) return;
  quizAnswered = true;
  const q = quizBank[quizIndex % quizBank.length];
  document.querySelectorAll('.choice-btn').forEach(b => b.disabled = true);
  const fb = document.getElementById('quiz-feedback');
  if (idx === q.correct) {
    btn.classList.add('correct');
    fb.className = 'feedback-box show ok';
    fb.textContent = '✅ 정답입니다!';
    quizCorrectCount++;
    document.getElementById('quiz-correct').textContent = quizCorrectCount;
  } else {
    btn.classList.add('wrong');
    fb.className = 'feedback-box show bad';
    fb.textContent = `❌ 틀렸습니다. 정답은 "\${q.word}"입니다.`;
    quizWrongCount++;
    document.getElementById('quiz-wrong').textContent = quizWrongCount;
    wrongList.push({ no: ++wrongNo, word: q.word, type: 'quiz', category: q.category, userAnswer: q.choices[idx], correctAnswer: q.word });
  }
  document.getElementById('quiz-next-btn').style.display = 'inline-flex';
}

function submitSubjective() {
  const val = document.getElementById('subjective-input').value.trim();
  if (!val || quizAnswered) return;
  quizAnswered = true;
  const q = quizBank[quizIndex % quizBank.length];
  const correct = val === q.word;
  const fb = document.getElementById('quiz-feedback');
  if (correct) {
    fb.className = 'feedback-box show ok';
    fb.textContent = '✅ 정답입니다!';
    quizCorrectCount++;
    document.getElementById('quiz-correct').textContent = quizCorrectCount;
  } else {
    fb.className = 'feedback-box show bad';
    fb.textContent = `❌ 틀렸습니다. 정답은 "\${q.word}"입니다.`;
    quizWrongCount++;
    document.getElementById('quiz-wrong').textContent = quizWrongCount;
    wrongList.push({ no: ++wrongNo, word: q.word, type: 'quiz', category: q.category, userAnswer: val, correctAnswer: q.word });
  }
  document.getElementById('quiz-next-btn').style.display = 'inline-flex';
}

function nextQuizQuestion() {
  quizIndex++;
  if (quizIndex >= totalCount) {
    endQuizPhase();
    return;
  }
  loadQuizQuestion(quizIndex);
  updateQuizProgress(quizIndex + 1, totalCount);
}

function endQuizPhase() {
  clearInterval(timerInterval);
  const params = new URLSearchParams(location.search);
  if (params.get('mode') === 'both') {
    location.href = '/exam/motion?mode=both&count=' + total;
  } else {
    location.href = '/exam/result';
  }
}
</script>
</body>
</html>
