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
        <p style="font-size:15px; font-weight:500; color:var(--text-sub); margin-top:6px;">방식과 범위를 고르고 시험을 시작하세요.</p>
      </div>
      <a href="index.jsp" class="btn btn-ghost btn-sm">← 메인으로</a>
    </div>

    <div class="setup-grid">
      <div class="option-group" style="grid-column: 1 / -1;">
        <h3>⚙️ 시험 방식</h3>
        <div class="mode-cards">
          <label class="mode-card">
            <input type="radio" name="exam-mode" value="quiz" id="mode-quiz" checked>
            <div class="mode-card-body">
              <div class="mode-card-title">🖼️ 객관식 / 주관식 퀴즈</div>
              <div class="mode-card-desc">수어 영상을 보고 알맞은 단어를 고르거나 직접 입력합니다. 수어를 처음 배우는 분께 추천해요.</div>
            </div>
          </label>
          <label class="mode-card">
            <input type="radio" name="exam-mode" value="cam" id="mode-cam">
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
        <h3>🔢 문제 수</h3>
        <div class="count-control" style="margin-bottom:10px;">
          <button class="count-btn" id="count-minus">−</button>
          <span class="count-display" id="count-display">10</span>
          <span style="font-size:15px; font-weight:600; color:var(--text-sub);">문제</span>
          <button class="count-btn" id="count-plus">＋</button>
        </div>
        <p style="font-size:13px; font-weight:500; color:var(--text-sub);">최소 5 · 최대 30문제<br><span id="both-note" style="display:none; color:var(--primary); font-weight:700;">※ "모두" 선택 시 퀴즈 + 수어 인식 각각 해당 수만큼 출제</span></p>
      </div>

      <div class="option-group">
        <h3>📚 시험 범위</h3>
        <div class="scope-chips">
          <label class="scope-chip"><input type="checkbox" id="scope-basic" checked> 🔤 기초 어휘</label>
          <label class="scope-chip"><input type="checkbox" id="scope-emergency" checked> 🚨 비상 어휘</label>
          <label class="scope-chip"><input type="checkbox" id="scope-word" checked> 🔍 개별 어휘</label>
        </div>
      </div>
    </div>

    <div class="setup-summary">
      <span style="font-size:15px; font-weight:700; color:var(--text-sub);">구성:</span>
      <span class="summary-tag" id="summary-mode">🖼️ 객관식/주관식</span>
      <span class="summary-tag" id="summary-count">10문제</span>
      <span class="summary-tag">합격 기준 70점</span>
    </div>

    <div style="display:flex; gap:12px; justify-content:flex-end;">
      <a href="learn_basic.html" class="btn btn-ghost">학습하고 오기</a>
      <button class="btn btn-primary btn-lg" onclick="startExam()">🚀 시험 시작</button>
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script>
let totalCount = 10;
const minQ = 5, maxQ = 30;
const countEl = document.getElementById('count-display');

document.getElementById('count-minus').onclick = () => { if (totalCount > minQ) { totalCount--; countEl.textContent = totalCount; updateSummary(); } };
document.getElementById('count-plus').onclick  = () => { if (totalCount < maxQ) { totalCount++; countEl.textContent = totalCount; updateSummary(); } };

document.querySelectorAll('input[name="exam-mode"]').forEach(r => {
  r.addEventListener('change', updateSummary);
});

function updateSummary() {
  const mode = document.querySelector('input[name="exam-mode"]:checked').value;
  const labels = { quiz: '🖼️ 객관식/주관식', cam: '📷 수어 인식', both: '🔀 퀴즈 + 수어 인식' };
  document.getElementById('summary-mode').textContent = labels[mode];
  document.getElementById('summary-count').textContent = mode === 'both' ? `각 ${totalCount}문제` : `${totalCount}문제`;
  document.getElementById('both-note').style.display = mode === 'both' ? 'inline' : 'none';
}

function startExam() {
  const mode = document.querySelector('input[name="exam-mode"]:checked').value;
  if (mode === 'quiz') {
    location.href = 'exam_progress.html';
  } else if (mode === 'cam') {
    location.href = 'exam_cam.html';
  } else {
    // 둘 다: 퀴즈 먼저 → 카메라 인식으로 이어짐 (exam_progress.html에서 처리)
    location.href = 'exam_progress.html?mode=both';
  }
}
</script>
</body>
</html>
