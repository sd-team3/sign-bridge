<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 개별 어휘 학습</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/shared.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/dict.css">
</head>
<body>

<header>
  <div class="logo">✋ SignBridge</div>
  <nav>
    <a href="${pageContext.request.contextPath}/">홈</a>
    <div class="nav-item has-sub">
      <a href="${pageContext.request.contextPath}/learn/basic">학습 <span class="nav-caret">▾</span></a>
      <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
          <a href="${pageContext.request.contextPath}/learn/basic" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔤</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">기초 어휘</span>
              <span class="nav-dropdown-desc">일상 속 기본 단어부터 차근차근</span>
            </span>
          </a>
          <a href="${pageContext.request.contextPath}/learn/list" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🚨</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">상황별 수어 학습</span>
              <span class="nav-dropdown-desc">지진, 화재 등 긴급 상황 어휘</span>
            </span>
          </a>
          <a href="${pageContext.request.contextPath}/learn/dict" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔍</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">개별 어휘 학습</span>
              <span class="nav-dropdown-desc">초성별로 찾거나 검색해서 학습</span>
            </span>
          </a>
        </div>
      </div>
    </div>
    <a href="${pageContext.request.contextPath}/exam/setup">시험</a>
    <div class="nav-item has-sub">
      <a href="${pageContext.request.contextPath}/play/chain">플레이존 <span class="nav-caret">▾</span></a>
      <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
          <a href="${pageContext.request.contextPath}/play/chain" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔗</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">수어 끝말잇기</span>
              <span class="nav-dropdown-desc">AI와 실시간 끝말잇기 대결</span>
            </span>
          </a>
          <a href="${pageContext.request.contextPath}/play/defense" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🎯</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">수어 디펜스</span>
              <span class="nav-dropdown-desc">떨어지는 단어를 수어로 막기</span>
            </span>
          </a>
        </div>
      </div>
    </div>
    <a href="${pageContext.request.contextPath}/board/list">게시판</a>
    <a href="${pageContext.request.contextPath}/mypage" class="active btn btn-ghost btn-sm" style="margin-left:12px;">내 계정</a>
  </nav>
</header>

<main>
  <div class="container page-body">

    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:20px; gap:16px;">
      <div>
        <h1 style="font-size:28px; font-weight:900; letter-spacing:-0.8px;">🔍 개별 어휘 학습</h1>
        <p style="font-size:14px; color:var(--text-sub); margin-top:5px;">초성별로 찾거나 검색·수어 인식으로 원하는 단어를 학습하세요.</p>
      </div>
      <a href="${pageContext.request.contextPath}/" class="btn btn-ghost btn-sm">← 메인으로</a>
    </div>

    <div class="dict-layout">

      <!-- 좌측: 초성 아코디언 -->
      <aside class="cho-sidebar" id="choSidebar">
        <div class="cho-sidebar-title">초성으로 찾기</div>
        <!-- 그룹 내용은 JS가 ALL_WORDS 로드 후 채움 -->
      </aside>

      <!-- 우측: 메인 영역 -->
      <div class="dict-main">
        <div class="search-row">
          <input type="text" id="searchInput" placeholder="단어를 검색하세요 (예: 사과, 병원, ㄱ)">
          <button class="btn btn-primary" id="searchBtn">검색</button>
          <button class="btn btn-ghost" id="camToggleBtn">🖐 수어로 검색</button>
        </div>

        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:10px;">
          <div class="main-results-label" id="mainResultsLabel" style="margin-bottom:0;">오늘의 추천 단어</div>
          <div class="sort-btns" id="sortBtns"></div>
        </div>
        <div class="main-results" id="mainResults"></div>
        <div id="pagination" class="pagination"></div>
      </div>

    </div>
  </div>
</main>

<footer>© 2025 SignBridge. 청각장애인과 세상을 잇는 다리.</footer>

<!-- 수어 인식 모달 -->
<dialog id="camModal" class="cam-modal">
  <div class="cam-modal-inner">
    <button class="cam-modal-close" id="camCloseBtn">✕</button>
    <div class="cam-modal-title">🖐 수어로 검색</div>
    <div class="cam-wrap">
      <video id="video-word" autoplay playsinline muted></video>
      <canvas id="canvas-word"></canvas>
    </div>
    <div class="cam-result" id="result-word">-</div>
    <div class="progress-bar"><div id="progressFill"></div></div>
    <div class="cam-modal-btns">
      <button class="btn btn-primary btn-sm" id="camSearchBtn">이 단어로 검색</button>
      <button class="btn btn-ghost btn-sm" id="camResetBtn">초기화</button>
    </div>
  </div>
</dialog>

<!-- 영상클릭시 설명 모달(description) -->
<dialog id="detailModal" class="detail-modal">
  <div class="detail-modal-inner">

    <!-- 오류신고 왼쪽위로 뺌 (기존엔 top-actions 안에서 닫기랑 같이 오른쪽에 있었음) -->
    <button class="detail-report-btn" id="detailReportBtn">⚠ 오류 신고</button>

    <!-- 오른쪽위엔 닫기버튼만 남음 -->
    <div class="detail-top-actions">
      <button class="detail-modal-close" id="detailCloseBtn">✕</button>
    </div>

    <!-- 이전/이후 단어 이동 버튼 - 히스토리 있을때만 JS가 display:flex로 보여줌 -->
    <button class="detail-nav-btn detail-nav-prev" id="detailPrevBtn">◀</button>
    <button class="detail-nav-btn detail-nav-next" id="detailNextBtn">▶</button>

    

    <!-- 여기서부터 detailSlideDrawer 전까지가 실제 스크롤되는 영역, 드로어는 이 밖이라 스크롤 안내려도 항상 보임 -->
    <div class="detail-scroll-content">

      <div class="detail-video-wrap">
        <video id="detailVideo" autoplay loop muted playsinline></video>
      </div>

      <!-- 컨트롤라인:재생속도/다시보기 -->
      <div class="detail-video-controls">
        <div class="detail-speed-control">
          <span class="detail-speed-label" id="detailSpeedLabel">1x</span>
          <input type="range" id="detailSpeedSlider" class="detail-speed-slider" min="0" max="7" step="1" value="3">
        </div>
        <button class="detail-ctrl-btn" id="detailReplayBtn">↺ 다시보기</button>
      </div>

      <div class="detail-word-name" id="detailWordName"></div>

      <div class="detail-divider"></div>
      <div class="detail-section-label">설명</div>
      <div class="detail-description" id="detailDescription"></div>

    </div>

    <!-- 슬라이드업 드로어: 화살표 버튼 + 관련 단어 2개, 항상 하단 고정, 열리면 토글바 위로 리스트만 펼쳐짐 -->
    <div class="detail-slide-drawer" id="detailSlideDrawer">
      <button class="detail-slide-toggle" id="detailSlideToggle">
        <span class="detail-slide-arrow">▲</span> 다른 단어 보기
      </button>
      <div class="detail-slide-content" id="detailSlideContent">
        <div class="detail-related-list" id="detailRelated"></div>
      </div>
    </div>

  </div>
</dialog>

<script>
const CTX = "${pageContext.request.contextPath}";
</script>
<script src="${pageContext.request.contextPath}/resources/js/sign-word.js"></script>

<!-- 수어 인식 모듈 -->
<script type="module">
  import { HandCameraWidget } from "http://localhost:8000/static/js/hand-camera.js";
  import { SignInputSession } from "${pageContext.request.contextPath}/resources/js/sign-input.js";

  // 자,모 조합 알고리즘
  const signInput = new SignInputSession({
    apiBase: CTX,
    onUpdate: function (data) {
      var composed = data.composedText || "";
      document.getElementById("result-word").textContent = composed || "-";
      var pct = (data.holdProgress || 0) * 100;
      document.getElementById("progressFill").style.width = pct + "%";
    },
  });

  // 카메라 손 추출
  const cam = new HandCameraWidget({
    videoEl: document.getElementById("video-word"),
    canvasEl: document.getElementById("canvas-word"),
    onFrame: function (landmarks) { signInput.submitFrame(landmarks); },
  });

  // 캠 클릭시 이전세션 초기화 후 카메라 인식 시작
  document.getElementById("camToggleBtn").addEventListener("click", async () => {
    document.getElementById("result-word").textContent = "-";
    document.getElementById("progressFill").style.width = "0%";
    try { await signInput.reset(); } catch (e) { console.error(e); }
    document.getElementById("camModal").showModal();
    await cam.start();
  });

  // 닫기 ... 카메라 스트림 정지
  document.getElementById("camCloseBtn").addEventListener("click", () => {
    document.getElementById("camModal").close();
    cam.stop();
  });

  // 세션만 리셋(카메라 그대로)
  document.getElementById("camResetBtn").addEventListener("click", async () => {
    try { await signInput.reset(); } catch (e) { console.error(e); }
  });

  // 일반검색과 로직동일
  document.getElementById("camSearchBtn").addEventListener("click", () => {
    const word = document.getElementById("result-word").textContent.trim();
    if (!word || word === "-") return;
    document.getElementById("searchInput").value = word;
    document.getElementById("camModal").close();
    cam.stop();
    currentPage = 1;
    runSearch();
  });

  window.cam = cam;
  window.signInput = signInput;
</script>

</body>
</html>