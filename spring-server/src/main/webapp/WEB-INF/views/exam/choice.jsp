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
        <div class="video-box" id="video-box">
          <video id="quiz-video" muted loop playsinline style="width:100%; height:100%; border-radius:var(--radius-sm); object-fit:cover; display:none;"></video>
          <div id="video-fallback" style="display:none; text-align:center;">
            <p>이 단어는 아직 영상이 준비되지 않았어요.</p>
          </div>
        </div>

        <div class="hint-area" style="margin: 12px 0;">
          <button class="btn btn-ghost btn-sm" id="hint-toggle-btn" onclick="toggleHint()">💡 힌트 보기</button>
          <div class="hint-box" id="hint-box" style="display:none; margin-top:8px; padding:12px 16px; background:var(--surface2); border-radius:var(--radius-sm); font-size:14px; color:var(--text-sub);"></div>
          <div class="hint-source" id="hint-source" style="display:none; margin-top:4px; font-size:11px; color:var(--text-sub); opacity:0.7;">일부 단어 뜻풀이 출처: 국립국어원 한국어기초사전</div>
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

        <div class="quiz-nav" style="justify-content:flex-end;">
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
const sessionId = params.get('sessionId');
const countParam = parseInt(params.get('count'), 10);
const total = isNaN(countParam) ? 10 : countParam;
const totalCount = examMode === 'both' ? Math.ceil(total / 2) : total;
const timeParam = parseInt(params.get('time'), 10);
const examSeconds = isNaN(timeParam) ? 600 : timeParam * 60;

let timerInterval = null;
let quizAnswered = false;
let quizIndex = 0;
let quizCorrectCount = 0, quizWrongCount = 0;
let wrongList = [];
let wrongNo = 0;
let dictWords = [];
let quizBank = [];

Promise.all([
  fetch('/learn/dict/search').then(res => res.json()),
  fetch(`/exam/api/questions?sessionId=\${sessionId}&phase=choice`).then(res => res.json())
])
  .then(([dictList, questions]) => {
    dictWords = dictList || [];
    quizBank = (questions || []).map(q => ({
      signWordId: q.signWordId,
      word: q.word,
      type: q.type,
      description: q.description,
      choices: q.choices || [],
      correct: q.choices ? q.choices.indexOf(q.word) : -1
    }));
    loadQuizQuestion(0);
    updateQuizProgress(1, totalCount);
    startTimer('quiz-timer', examSeconds, endQuizPhase);
  })
  .catch(err => {
    console.error('문제 로드 실패', err);
  });

function loadQuizQuestion(idx) {
  const q = quizBank[idx % quizBank.length];

  const hintBtn = document.getElementById('hint-toggle-btn');
  const hintBox = document.getElementById('hint-box');
  const hintSource = document.getElementById('hint-source');
  hintBox.style.display = 'none';
  hintSource.style.display = 'none';
  if (q.description) {
    hintBtn.style.display = 'inline-flex';
    hintBox.textContent = q.description;
  } else {
    hintBtn.style.display = 'none';
  }

  const videoEl = document.getElementById('quiz-video');
  const fallbackEl = document.getElementById('video-fallback');
  const matched = dictWords.find(w => w.signWordName === q.word);
  let videoUrl = matched ? (matched.signWordVideo || '') : '';
  if (videoUrl.startsWith('http://')) videoUrl = videoUrl.replace('http://', 'https://');

  if (videoUrl.toLowerCase().endsWith('.mp4')) {
  videoEl.src = '/learn/dict/video-proxy?url=' + encodeURIComponent(videoUrl);
  videoEl.style.display = 'block';
  fallbackEl.style.display = 'none';
  videoEl.play().catch(() => {});
} else {
  videoEl.style.display = 'none';
  fallbackEl.style.display = 'block';
}

  const isSubjective = q.type === 'subjective';

  document.getElementById('multiple-choice-area').style.display = isSubjective ? 'none' : 'block';
  document.getElementById('subjective-area').style.display = isSubjective ? 'block' : 'none';
  document.getElementById('quiz-type-label').textContent = isSubjective ? '✏️ 주관식' : '🖼️ 객관식';

  if (!isSubjective) {
    const list = document.getElementById('choices-list');
    const labels = ['①','②','③','④'];
    list.innerHTML = q.choices.map((c, i) =>
      `<button class="choice-btn" onclick="selectChoice(this, \${i})"><span class="choice-label">\${labels[i]}</span> \${c}</button>`
    ).join('');
  } else {
    document.getElementById('subjective-input').value = '';
  }

  document.getElementById('quiz-feedback').className = 'feedback-box';
  document.getElementById('quiz-next-btn').style.display = 'none';
  quizAnswered = false;
}

function updateQuizProgress(cur, total) {
  const pct = Math.round((cur / total) * 100);
  document.getElementById('quiz-prog-text').textContent = `퀴즈 \${cur} / \${total}`;
  document.getElementById('quiz-prog-pct').textContent = pct + '%';
  document.getElementById('quiz-prog-fill').style.width = pct + '%';
  document.getElementById('quiz-q-badge').textContent = `문제 \${cur}`;
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

function selectChoice(btn, idx) {
  if (quizAnswered) return;
  quizAnswered = true;
  const q = quizBank[quizIndex % quizBank.length];
  document.querySelectorAll('.choice-btn').forEach(b => b.disabled = true);
  const fb = document.getElementById('quiz-feedback');
  const isCorrect = idx === q.correct;

  if (isCorrect) {
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
    wrongList.push({ no: ++wrongNo, word: q.word, type: 'quiz', userAnswer: q.choices[idx], correctAnswer: q.word });
  }

  saveAnswer(q, quizIndex, q.choices[idx], isCorrect);
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
    wrongList.push({ no: ++wrongNo, word: q.word, type: 'quiz', userAnswer: val, correctAnswer: q.word });
  }

  saveAnswer(q, quizIndex, val, correct);
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
  const isBoth = params.get('mode') === 'both';

  if (isBoth) {
    const passParam = params.get('pass');
    const timeParam2 = params.get('time');
    location.href = '/exam/motion?mode=both&sessionId=' + sessionId + '&count=' + total
      + '&quizCorrect=' + quizCorrectCount
      + '&quizWrong=' + quizWrongCount
      + (passParam ? '&pass=' + passParam : '')
      + (timeParam2 ? '&time=' + timeParam2 : '');
    return;
  }

  const body = new URLSearchParams();
  body.append('correctCount', quizCorrectCount);
  body.append('totalCount', totalCount);

  fetch(`/exam/api/\${sessionId}/finish`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body
  })
    .then(() => {
      const passParam = params.get('pass');
      location.href = '/exam/result?sessionId=' + sessionId
        + (passParam ? '&pass=' + passParam : '');
    })
    .catch(err => {
      console.error('시험 종료 처리 실패', err);
      const passParam = params.get('pass');
      location.href = '/exam/result?sessionId=' + sessionId
        + (passParam ? '&pass=' + passParam : '');
    });
}

function saveAnswer(q, questionNo, userAnswer, isCorrect) {
  const body = new URLSearchParams();
  body.append('signWordId', q.signWordId);
  body.append('questionNo', questionNo + 1);
  body.append('userAnswer', userAnswer);
  body.append('isCorrect', isCorrect);

  fetch(`/exam/api/\${sessionId}/answer`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body
  }).catch(err => console.error('답안 저장 실패', err));
}

function toggleHint() {
  const box = document.getElementById('hint-box');
  const source = document.getElementById('hint-source');
  const show = box.style.display === 'none';
  box.style.display = show ? 'block' : 'none';
  source.style.display = show ? 'block' : 'none';
}
</script>
</body>
</html>
