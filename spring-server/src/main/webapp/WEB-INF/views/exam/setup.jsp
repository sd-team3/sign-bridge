<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 수어 시험 설정</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div style="display:flex; align-items:flex-start; justify-content:space-between; gap:16px; flex-wrap:wrap; margin-bottom:28px;">
      <div>
        <h1 style="font-size:26px; font-weight:900; letter-spacing:-0.4px;">📝 수어 시험</h1>
        <p style="font-size:15px; font-weight:500; color:var(--text-sub); margin-top:6px;">원하는 방식과 문제 수를 고른 후, 실력을 테스트하세요.</p>
      </div>
    </div>

    <div class="setup-grid">
      <div class="option-group" style="grid-column: 1 / -1;">
        <h3>⚙️ 시험 방식</h3>
        <div class="mode-cards">
          <label class="mode-card">
            <input type="radio" name="exam-mode" value="choice" id="mode-choice" checked>
            <div class="mode-card-body">
              <div class="mode-card-title">🖼️ 객관식 / 주관식 퀴즈</div>
              <div class="mode-card-desc">수어 영상을 보고 알맞은 단어를 고르거나 직접 입력합니다. 수어를 처음 배우는 분께 추천해요.</div>
            </div>
          </label>
          <label class="mode-card">
            <input type="radio" name="exam-mode" value="motion" id="mode-motion">
            <div class="mode-card-body">
              <div class="mode-card-title">📷 카메라 수어 인식</div>
              <div class="mode-card-desc">화면에 표시된 단어를 직접 수어로 표현합니다. AI가 실시간으로 인식해서 채점합니다.</div>
            </div>
          </label>
          <label class="mode-card">
            <input type="radio" name="exam-mode" value="both" id="mode-both">
            <div class="mode-card-body">
              <div class="mode-card-title">🔀 퀴즈 → 수어 인식 순서로 모두</div>
              <div class="mode-card-desc">퀴즈 문제를 먼저 풀고, 이어서 카메라 수어 인식 문제를 풉니다. 설정한 문제 수가 각각 출제됩니다.</div>
            </div>
          </label>
        </div>
      </div>

      <div class="option-group">
        <div class="setting-row-grid">

          <div class="setting-col">
            <h3 class="setting-col-title">🔢 문제 수</h3>
            <div class="count-control count-control-sm">
              <button class="count-btn count-btn-sm" id="count-minus">−</button>
              <span class="count-display count-display-sm" id="count-display">10</span>
              <button class="count-btn count-btn-sm" id="count-plus">＋</button>
            </div>
            <p class="setting-hint">최소 10 · 최대 30문제</p>
          </div>

          <div class="setting-col">
            <h3 class="setting-col-title">🎯 합격 점수</h3>
            <div class="count-control count-control-sm">
              <button class="count-btn count-btn-sm" id="pass-minus">−</button>
              <span class="count-display count-display-sm" id="pass-display">70</span>
              <button class="count-btn count-btn-sm" id="pass-plus">＋</button>
            </div>
            <p class="setting-hint">최소 50 · 최대 100점</p>
          </div>

          <div class="setting-col">
            <h3 class="setting-col-title">⏱️ 시험 시간</h3>
            <div class="count-control count-control-sm">
              <button class="count-btn count-btn-sm" id="time-minus">−</button>
              <span class="count-display count-display-sm" id="time-display">10</span>
              <button class="count-btn count-btn-sm" id="time-plus">＋</button>
            </div>
            <p class="setting-hint">최소 5 · 최대 30분</p>
          </div>

        </div>
      </div>

      <div class="option-group">
        <h3>📋 요약</h3>
        <div class="setup-summary" style="margin-top:14px;">
          <span style="font-size:14px; font-weight:700; color:var(--text-sub);">구성:</span>
          <span class="summary-tag" id="summary-mode">🖼️ 객관식/주관식</span>
          <span class="summary-tag" id="summary-count">10문제</span>
          <span class="summary-tag" id="summary-pass">합격 기준 70점</span>
        </div>
      </div>
    </div>

    <div style="display:flex; gap:12px; justify-content:flex-end;">
      <a href="/learn" class="btn btn-ghost">학습하고 오기</a>
      <button class="btn btn-primary btn-lg" onclick="startExam()">🚀 시험 시작</button>
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script>
let totalCount = 10;
const minQ = 10, maxQ = 30;
const countEl = document.getElementById('count-display');

let passScore = 70;
const minPass = 50, maxPass = 100;
const passEl = document.getElementById('pass-display');

let examMinutes = 10;
const minTime = 5, maxTime = 30;
const timeEl = document.getElementById('time-display');

document.getElementById('count-minus').onclick = () => { if (totalCount > minQ) { totalCount -= 10; countEl.textContent = totalCount; updateSummary(); } };
document.getElementById('count-plus').onclick  = () => { if (totalCount < maxQ) { totalCount += 10; countEl.textContent = totalCount; updateSummary(); } };

document.getElementById('pass-minus').onclick = () => { if (passScore > minPass) { passScore -= 5; passEl.textContent = passScore; updateSummary(); } };
document.getElementById('pass-plus').onclick  = () => { if (passScore < maxPass) { passScore += 5; passEl.textContent = passScore; updateSummary(); } };

document.getElementById('time-minus').onclick = () => { if (examMinutes > minTime) { examMinutes -= 5; timeEl.textContent = examMinutes; updateSummary(); } };
document.getElementById('time-plus').onclick  = () => { if (examMinutes < maxTime) { examMinutes += 5; timeEl.textContent = examMinutes; updateSummary(); } };

document.querySelectorAll('input[name="exam-mode"]').forEach(r => {
  r.addEventListener('change', updateSummary);
});

function updateSummary() {
  const mode = document.querySelector('input[name="exam-mode"]:checked').value;
  const labels = { choice: '🖼️ 객관식/주관식', motion: '📷 수어 인식', both: '🔀 퀴즈 + 수어 인식' };
  document.getElementById('summary-mode').textContent = labels[mode];
  document.getElementById('summary-count').textContent = mode === 'both' ? `각 \${totalCount / 2}문제` : `\${totalCount}문제`;
  document.getElementById('summary-pass').textContent = `합격 기준 \${passScore}점`;
}

function startExam() {
  const mode = document.querySelector('input[name="exam-mode"]:checked').value;
  const extra = `&pass=\${passScore}&time=\${examMinutes}`;

  const formData = new URLSearchParams();
  formData.append('mode', mode);
  formData.append('count', totalCount);

  fetch('/exam/api/start', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: formData
  })
    .then(res => res.json())
    .then(data => {
      if (data.error) {
        alert('로그인이 필요합니다.');
        location.href = '/member/login';
        return;
      }
      const sessionId = data.sessionId;
      if (mode === 'choice') {
        location.href = '/exam/choice?sessionId=' + sessionId + '&count=' + totalCount + extra;
      } else if (mode === 'motion') {
        location.href = '/exam/motion?sessionId=' + sessionId + '&count=' + totalCount + extra;
      } else {
        location.href = '/exam/choice?sessionId=' + sessionId + '&mode=both&count=' + totalCount + extra;
      }
    })
    .catch(err => {
      console.error('시험 시작 실패', err);
      alert('시험을 시작하지 못했습니다. 잠시 후 다시 시도해주세요.');
    });
}
</script>
</body>
</html>
