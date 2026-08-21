<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="_csrf" content="${_csrf.token}">
<meta name="_csrf_header" content="${_csrf.headerName}">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - 수어 사전</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/shared.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/dict.css">
</head>
<body>

<%@ include file="/WEB-INF/views/includes/header.jsp" %>

<main>
  <div class="container page-body">

    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:20px; gap:16px;">
      <div>
        <h1 style="font-size:28px; font-weight:900; letter-spacing:-0.8px;">🔍 수어 사전</h1>
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


<%@ include file="/WEB-INF/views/includes/footer.jsp" %>

<!-- 수어 인식 모달 -->
<dialog id="camModal" class="cam-modal">
  <div class="cam-modal-inner">
    <button class="cam-modal-close" id="camCloseBtn">✕</button>
    <div class="cam-modal-title">🖐 수어로 검색</div>
    <div class="cam-wrap" id="camWrap">
      <video id="video-word" autoplay playsinline muted></video>
      <canvas id="canvas-word"></canvas>
      <div class="cam-pause-overlay" id="camPauseOverlay">
        <span>⏸ 클릭해서 재개</span>
      </div>
    </div>
    <div class="cam-status" id="camStatus">카메라를 준비하는 중...</div>

    <div class="cam-confidence-row">
      <div class="cam-confidence-gauge">
        <svg viewBox="0 0 36 36" class="cam-gauge-svg">
          <path class="cam-gauge-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" />
          <path class="cam-gauge-fill" id="camGaugeFill" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" />
        </svg>
        <span class="cam-gauge-label" id="camGaugeLabel">0%</span>
      </div>
    </div>

    

    <div class="cam-result" id="result-word">-</div>
    <div class="progress-bar"><div id="progressFill"></div></div>
    <div class="cam-modal-btns">
      <button class="btn btn-primary btn-sm" id="camSearchBtn" disabled>이 단어로 검색</button>
      <button class="btn btn-ghost btn-sm" id="camResetBtn">초기화</button>
    </div>
  </div>
</dialog>

<!-- 영상클릭시 설명 모달(description) -->
<dialog id="detailModal" class="detail-modal">
  <div class="detail-modal-inner">

    <!-- 오류신고 -->
    <button class="detail-report-btn" id="detailReportBtn">⚠ 오류 신고</button>

    <!-- 닫기버튼-->
    <div class="detail-top-actions">
      <button class="detail-modal-close" id="detailCloseBtn">✕</button>
    </div>

    <!-- 이전/이후 단어 이동 버튼 - 히스토리 있을때만 -->
    <button class="detail-nav-btn detail-nav-prev" id="detailPrevBtn">◀</button>
    <button class="detail-nav-btn detail-nav-next" id="detailNextBtn">▶</button>

    

    <!-- 실제 스크롤 영역 -->
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
      <span class="fav-star detail-fav-star" id="detailFavStar">☆</span>
      

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

<!-- 오류 신고 모달 -->
<dialog id="reportModal" class="report-modal">
  <div class="report-modal-inner">
    <button class="report-modal-close" id="reportCloseBtn">✕</button>
    <div class="report-modal-title">⚠ 오류 신고</div>
    <div class="report-modal-word" id="reportTargetWord"></div>
    <select id="reportCategorySelect" class="form-input">
    <option>동작 인식 오류</option>
    <option>영상 재생 오류</option>
    <option>번역 · 뜻풀이 오류</option>
    <option>화면 · 디자인 오류</option>
    <option>기타</option>
  </select>
    <textarea id="reportReasonInput" class="report-reason-input" placeholder="어떤 부분이 잘못됐는지 알려주세요 (선택사항)"></textarea>
    <div class="report-modal-btns">
      <button class="btn btn-ghost btn-sm" id="reportCancelBtn">취소</button>
      <button class="btn btn-danger btn-sm" id="reportSubmitBtn">신고 접수</button>
    </div>
  </div>
</dialog>

<!-- 신고 접수 결과 안내 모달 (성공/실패 공용) -->
<dialog id="reportStatusModal" class="report-status-modal">
  <div class="report-status-inner">
    <div class="report-status-icon" id="reportStatusIcon">✓</div>
    <div class="report-status-msg" id="reportStatusMsg"></div>
    <button class="btn btn-primary btn-sm" id="reportStatusOkBtn">확인</button>
  </div>
</dialog>

<script>
const CTX = "${pageContext.request.contextPath}";
</script>
<script src="${pageContext.request.contextPath}/resources/js/sign-word.js"></script>

<script>
// 오답노트 등에서 word 파라미터로 진입 시 해당 단어 상세 모달 자동 오픈
(function () {
  const params = new URLSearchParams(location.search);
  const targetWordName = params.get("word");
  if (!targetWordName) return;

  loadAllWords().then(() => {
    const target = ALL_WORDS.find(w => w.signWordName === targetWordName);
    if (target) openDetailModal(target);
  });
})();
</script>

<!-- 수어 인식 모듈 -->
<script type="module">
  import { initDictCamera } from "${pageContext.request.contextPath}/resources/js/dict-camera.js";

  const { cam, signInput } = initDictCamera({
    ctx: CTX,
    onSearch: function (word) {
      document.getElementById("searchInput").value = word;
      currentPage = 1;
      runSearch();
    },
  });

  window.cam = cam;
  window.signInput = signInput;
</script>

</body>
</html>
