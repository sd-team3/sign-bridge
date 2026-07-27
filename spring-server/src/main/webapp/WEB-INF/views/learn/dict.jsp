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
<style>
  .dict-layout { display:flex; gap:24px; align-items:flex-start; }

  /* 좌측 초성 아코디언 사이드바 */
  .cho-sidebar { flex:0 0 220px; position:sticky; top:16px; max-height:calc(100vh - 32px); overflow-y:auto; border:1px solid #eee; border-radius:12px; }
  .cho-sidebar-title { font-size:13px; color:var(--text-sub); font-weight:700; padding:12px 14px 8px; }
  .cho-group { border-top:1px solid #f0f0f0; }
  .cho-group summary { list-style:none; cursor:pointer; padding:10px 14px; font-weight:800; font-size:15px; display:flex; justify-content:space-between; align-items:center; }
  .cho-group summary::-webkit-details-marker { display:none; }
  .cho-group summary .cho-count { font-size:12px; font-weight:500; color:var(--text-sub); }
  .cho-group[open] summary { background:#f2f8f5; color:var(--brand,#1e8e5a); }
  .cho-group-list { max-height:220px; overflow-y:auto; padding:0 14px 10px; }
  .cho-word-item { padding:6px 4px; font-size:14px; cursor:pointer; border-radius:6px; }
  .cho-word-item:hover { background:#f2f8f5; }
  .cho-group-empty { padding:6px 4px; font-size:13px; color:var(--text-sub); }

  /* 메인 영역 */
  .dict-main { flex:1; min-width:0; }
  .search-row { display:flex; gap:8px; margin-bottom:16px; }
  .search-row input { flex:1; padding:10px 14px; border:1px solid #ddd; border-radius:8px; }
  .main-results-label { font-size:13px; color:var(--text-sub); margin-bottom:10px; }
  .main-results {
  display:grid;
  grid-template-columns:repeat(3, 1fr);
  gap:14px;
  min-height: 520px;
  align-content: start;
  overflow-y:auto;
  padding-right:4px;
}

@media (max-width: 768px) {
  .dict-layout {
    flex-direction: column;
  }
  .cho-sidebar {
    flex: none;
    width: 100%;
    position: static;
    max-height: 300px;
  }
  .main-results {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 480px) {
  .main-results {
    grid-template-columns: repeat(1, 1fr);
  }
}
  .word-card { border:1px solid #eee; border-radius:14px; overflow:hidden; background:#fafafa; cursor:pointer; }
  .word-card video { width:100%; aspect-ratio:4/3; object-fit:cover; background:#000; display:block; }

  
  /* error */
  .word-video-wrap { position:relative; width:100%; aspect-ratio:4/3; background:#000; }
  .word-video-wrap video { width:100%; height:100%; object-fit:cover; display:block; }
  .word-video-wrap.no-thumb { background:#f0f0f0; }
  .video-unavailable {
    position:absolute; top:0; left:0; width:100%; height:100%;
    display:none; align-items:center; justify-content:center;
    background:#f0f0f0; color:var(--text-sub); font-size:13px; font-weight:600;
  }

  .word-card-name {
  padding:8px 10px;
  font-weight:800;
  font-size:14px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
  .main-results-empty { padding:24px; color:var(--text-sub); font-size:14px; }

  .pagination { display:flex; gap:6px; justify-content:center; margin-top:16px; }
  .page-btn { border:1px solid #ddd; background:#fff; border-radius:6px; padding:6px 12px; font-size:13px; cursor:pointer; }
  .page-btn.active { background:var(--brand,#1e8e5a); color:#fff; border-color:var(--brand,#1e8e5a); }

  /* 수어 인식 모달 */
  .cam-modal {
    border:none; border-radius:20px; padding:0; max-width:480px; width:92vw; max-height:85vh;
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    margin: 0;
  }
  .cam-modal::backdrop { background:rgba(0,0,0,.55); }
  .cam-modal-inner { padding:20px; position:relative; max-height:85vh; overflow-y:auto; }
  .cam-modal-title { font-weight:800; font-size:16px; margin-bottom:12px; }
  .cam-modal-close { position:absolute; top:14px; right:14px; border:none; background:none; font-size:20px; cursor:pointer; line-height:1; }
  .cam-wrap { position:relative; width:100%; aspect-ratio:4/3; margin:0 auto; border-radius:12px; overflow:hidden; background:#000; }
  .cam-wrap video, .cam-wrap canvas { position:absolute; top:0; left:0; width:100%; height:100%; object-fit:cover; transform:scaleX(-1); }
  .cam-result { font-size:26px; font-weight:800; text-align:center; margin:14px 0; min-height:36px; }
  .cam-modal-btns { display:flex; gap:8px; justify-content:center; }
  
  /* 단어 상세 모달 (강의식) */
  .detail-modal {
    border:none; border-radius:24px; padding:0; max-width:640px; width:92vw; max-height:88vh;
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    margin: 0;
  }
.detail-modal::backdrop { background:rgba(0,0,0,.65); }
.detail-modal-inner { padding:32px; position:relative; max-height:88vh; overflow-y:auto; display:flex; flex-direction:column; align-items:center; }
.detail-modal-close { position:absolute; top:16px; right:18px; border:none; background:none; font-size:22px; cursor:pointer; line-height:1; color:var(--text-sub); }

.detail-video-wrap { width:100%; max-width:440px; aspect-ratio:4/3; border-radius:16px; overflow:hidden; background:#000; box-shadow:0 8px 24px rgba(0,0,0,.15); }
.detail-video-wrap video { width:100%; height:100%; object-fit:cover; display:block; }

.detail-word-name { font-size:26px; font-weight:900; letter-spacing:-0.5px; margin-top:18px; text-align:center; }

.detail-divider { width:48px; height:3px; background:var(--brand,#1e8e5a); border-radius:2px; margin:16px 0; }

.detail-section-label { font-size:13px; font-weight:800; color:var(--brand,#1e8e5a); letter-spacing:1px; text-transform:uppercase; margin-bottom:8px; text-align:center; }

.detail-description { font-size:16px; line-height:1.7; color:#333; text-align:center; max-width:480px; background:#f7faf8; border:1px solid #e6efe9; border-radius:14px; padding:18px 22px; }
  .page-dots { color:var(--text-sub); font-weight:700; }
  /* 상단 액션 바 (오류신고 + 닫기, 오른쪽 끝에 나란히) */
.detail-top-actions {
  position: absolute;
  top: 14px;
  right: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
  z-index: 5;
}

.detail-report-btn {
  border: 1px solid #e2c4c4;
  background: #fff5f5;
  color: #b23b3b;
  font-size: 12px;
  font-weight: 700;
  padding: 6px 10px;
  border-radius: 8px;
  cursor: pointer;
  white-space: nowrap;
}
.detail-report-btn:hover {
  background: #fde8e8;
}

.detail-modal-close {
  border: none;
  background: none;
  font-size: 20px;
  cursor: pointer;
  line-height: 1;
  color: var(--text-sub);
  padding: 4px;
}

/* 영상 컨트롤 (재생속도/다시보기) */
.detail-video-controls {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin-top: 12px;
}

.detail-ctrl-btn {
  border: 1px solid #ddd;
  background: #fff;
  border-radius: 8px;
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  color: #333;
}
.detail-ctrl-btn:hover {
  background: #f2f8f5;
  border-color: var(--brand, #1e8e5a);
  color: var(--brand, #1e8e5a);
}
.detail-ctrl-btn.active {
  background: var(--brand, #1e8e5a);
  border-color: var(--brand, #1e8e5a);
  color: #fff;
}

/* 조회수 메타 */
.detail-meta {
  font-size: 13px;
  color: var(--text-sub);
  margin-top: 6px;
  text-align: center;
}

/* 슬라이드업 드로어 */
.detail-slide-drawer {
  position: sticky;
  bottom: 0;
  left: 0;
  right: 0;
  margin-top: 20px;
  background: #fff;
  border-top: 1px solid #eee;
  border-radius: 16px 16px 0 0;
  overflow: hidden;
}

.detail-slide-toggle {
  width: 100%;
  border: none;
  background: #fafafa;
  padding: 10px 0;
  font-size: 13px;
  font-weight: 700;
  color: var(--text-sub);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}
.detail-slide-toggle:hover {
  background: #f2f8f5;
  color: var(--brand, #1e8e5a);
}

.detail-slide-arrow {
  display: inline-block;
  transition: transform 0.25s ease;
  font-size: 11px;
}
.detail-slide-drawer.open .detail-slide-arrow {
  transform: rotate(180deg);
}

.detail-slide-content {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.28s ease;
}

/* 관련 단어 리스트 (유튜브 관련영상 스타일 - 썸네일+제목 카드형) */
.detail-related-list {
  padding: 14px 20px 20px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.related-item {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  padding: 8px;
  border-radius: 10px;
}
.related-item:hover {
  background: #f2f8f5;
}

.related-thumb {
  width: 88px;
  aspect-ratio: 4/3;
  border-radius: 8px;
  overflow: hidden;
  background: #000;
  flex-shrink: 0;
}
.related-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.related-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.related-name {
  font-weight: 800;
  font-size: 14px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.related-desc {
  font-size: 12px;
  color: var(--text-sub);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
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

        <div class="main-results-label" id="mainResultsLabel">오늘의 추천 단어</div>
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

    <!-- 상단 우측: 오류신고 + 닫기 버튼 -->
    <div class="detail-top-actions">
      <button class="detail-report-btn" id="detailReportBtn">⚠ 오류 신고</button>
      <button class="detail-modal-close" id="detailCloseBtn">✕</button>
    </div>

    <div class="detail-video-wrap">
      <video id="detailVideo" autoplay loop muted playsinline></video>
    </div>

    <!-- 영상 컨트롤: 재생속도 / 다시보기 -->
    <div class="detail-video-controls">
      <button class="detail-ctrl-btn" id="detailSlowBtn">0.5x</button>
      <button class="detail-ctrl-btn" id="detailReplayBtn">↺ 다시보기</button>
    </div>

    <div class="detail-word-name" id="detailWordName"></div>

    <!-- 조회수 -->
    <div class="detail-meta" id="detailMeta"></div>

    <div class="detail-divider"></div>
    <div class="detail-section-label">설명</div>
    <div class="detail-description" id="detailDescription"></div>

    <!-- 슬라이드업 드로어: 화살표 버튼 + 관련 단어 2개 -->
    <div class="detail-slide-drawer" id="detailSlideDrawer">
      <button class="detail-slide-toggle" id="detailSlideToggle">
        <span class="detail-slide-arrow">▲</span> 관련 단어 보기
      </button>
      <div class="detail-slide-content" id="detailSlideContent">
        <div class="detail-related-list" id="detailRelated"></div>
      </div>
    </div>

  </div>
</dialog>



<script>
const CTX = "${pageContext.request.contextPath}";
let ALL_WORDS = [];
let currentPage = 1;
const PAGE_SIZE = 6;

/* ─────────────────────────────────────────────
   1) 전체 단어 로드 (API 연동)
───────────────────────────────────────────── */
function loadAllWords() {
  return fetch(CTX + "/learn/dict/search")
    .then(response => {
      if (!response.ok) throw new Error("네트워크 응답 이상");
      return response.json();
    })
    .then(list => { 
      ALL_WORDS = list || []; 
    })
    .catch(err => {
      console.error("단어 목록 로드 중 에러 발생:", err);
    });
}

/* ─────────────────────────────────────────────
   2) 한글 초성 유틸
───────────────────────────────────────────── */
const CHO = ['ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ','ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
const JUNG = ['ㅏ','ㅐ','ㅑ','ㅒ','ㅓ','ㅔ','ㅕ','ㅖ','ㅗ','ㅘ','ㅙ','ㅚ','ㅛ','ㅜ','ㅝ','ㅞ','ㅟ','ㅠ','ㅡ','ㅢ','ㅣ'];
const JONG = ['', 'ㄱ','ㄲ','ㄳ','ㄴ','ㄵ','ㄶ','ㄷ','ㄹ','ㄺ','ㄻ','ㄼ','ㄽ','ㄾ','ㄿ','ㅀ','ㅁ','ㅂ','ㅄ','ㅅ','ㅆ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
const BASIC_CHO = ['ㄱ','ㄴ','ㄷ','ㄹ','ㅁ','ㅂ','ㅅ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];

// 완성형 음절이 아닌 단독 자모(호환 자모) 판별용 유니코드 범위
function isConsonantJamo(ch) {
  const code = ch.charCodeAt(0);
  return code >= 0x3131 && code <= 0x314E;
}
function isVowelJamo(ch) {
  const code = ch.charCodeAt(0);
  return code >= 0x314F && code <= 0x3163;
}

// 단어 안 모든 음절의 초성 배열 (검색/필터용)
function choseongListOf(word) {
  const result = [];
  if (!word) return result;
  for (const ch of word) {
    const code = ch.charCodeAt(0) - 0xAC00;
    if (code >= 0 && code <= 11171) {
      result.push(CHO[Math.floor(code / (21 * 28))]);
    } else if (isConsonantJamo(ch)) {
      // 단독 자음 낱자(예: "ㄱ" 자체) 도 초성 검색/분류 대상에 포함
      result.push(ch);
    }
  }
  return result;
}

// 첫 글자 초성 (사전 그룹핑용)
function firstChoseongOf(word) {
  const list = choseongListOf(word);
  return list.length ? list[0] : null;
}

// 단어가 괄호로 시작하면(예: "(가스불을)켜다") 분류 불가로 보고 기타로 보냄
function startsWithParenthesis(word) {
  return /^[(（]/.test(word);
}

// 쉼표(,)로 구분된 여러 표현 중, 괄호로 시작하지 않는 조각들의 초성/모음 그룹을 전부 뽑아냄
// 예: "뽀뽀,입맞춤,키스,맞추다" -> ["ㅃ","ㅇ","ㅋ","ㅁ"]
function classifyGroups(word) {
  if (!word) return ["기타"];

  const parts = word.split(",").map(p => p.trim()).filter(p => p.length > 0);
  const targets = parts.length > 0 ? parts : [word];

  const keys = new Set();
  targets.forEach(part => {
    if (startsWithParenthesis(part)) {
      keys.add("기타");
      return;
    }
    if (part.length === 1 && isVowelJamo(part[0])) {
      keys.add("모음");
      return;
    }
    const cho = firstChoseongOf(part);
    keys.add(cho || "기타");
  });

  return [...keys];
}

// 완성형 음절 한 글자 -> 초성 낱자 하나. 단독 자음이면 자기 자신 리턴. 그 외 null.
function choseongOfChar(ch) {
  const code = ch.charCodeAt(0) - 0xAC00;
  if (code >= 0 && code <= 11171) {
    return CHO[Math.floor(code / (21 * 28))];
  }
  if (isConsonantJamo(ch)) return ch;
  return null;
}

// 단어 속 한 글자(nameCh)가 검색어 한 글자(keyCh)와 매칭되는지 판단
// keyCh가 초성 낱자면: nameCh의 초성만 뽑아 비교(완성형이든 초성낱자든 상관없이)
// keyCh가 완성형 글자면: nameCh와 그대로 비교
function charMatches(nameCh, keyCh) {
  if (isConsonantJamo(keyCh)) {
    return choseongOfChar(nameCh) === keyCh;
  }
  return nameCh === keyCh;
}

// name 안에서 keyword 시퀀스가 "연속으로(순서 그대로, 건너뛰기 없이)" 등장하는지 탐색
// 완성형 글자, 초성 낱자가 섞인 검색어도 처리 가능 (예: "사ㄱ")
function matchesSequential(name, keyword) {
  if (!keyword) return true;
  if (!name) return false;
  const nameChars = [...name];
  const keyChars = [...keyword];
  for (let start = 0; start <= nameChars.length - keyChars.length; start++) {
    let allMatch = true;
    for (let i = 0; i < keyChars.length; i++) {
      if (!charMatches(nameChars[start + i], keyChars[i])) { allMatch = false; break; }
    }
    if (allMatch) return true;
  }
  return false;
}

// 검색창에 초성만 입력해도, 완성형+초성 섞어 입력해도, 일반 단어 입력해도 다 처리
function matchesQuery(name, keyword) {
  if (!keyword) return true;
  if (!name) return false;
  return matchesSequential(name, keyword);
}

/* ─────────────────────────────────────────────
   3) 좌측 초성 아코디언 렌더링
───────────────────────────────────────────── */
function renderChoSidebar() {
  const sidebar = document.getElementById("choSidebar");
  if (!sidebar) return;
  sidebar.querySelectorAll(".cho-group").forEach(el => el.remove());

  // CHO 19개(된소리 포함) + 모음 + 기타 로 그룹 구성
  const groupKeys = [...CHO, "모음", "기타"];
  const groups = {};
  groupKeys.forEach(k => groups[k] = []);

  // classifyGroups로 분류 (단독모음->모음, 단독자음/완성형 초성->해당 초성, 괄호로 시작->기타, 못찾으면->기타)
  // 쉼표(,)로 여러 표현이 묶인 단어는 각 표현의 초성마다 전부 걸리도록 배열로 리턴받음
  ALL_WORDS.forEach(w => {
    const keys = classifyGroups(w.signWordName);
    keys.forEach(key => {
      (groups[key] || groups["기타"]).push(w);
    });
  });

  // 그룹별 가나다순 정렬
  groupKeys.forEach(key => {
    const words = groups[key].sort((a, b) => a.signWordName.localeCompare(b.signWordName, "ko"));
    // 모음/기타 그룹은 비어있으면 아예 렌더링 스킵
    if (words.length === 0 && (key === "기타" || key === "모음")) return;

    const details = document.createElement("details");
    details.className = "cho-group";

    // 개수 표시
    const summary = document.createElement("summary");
    summary.innerHTML = "<span>" + key + "</span><span class=\"cho-count\">" + words.length + "</span>";
    details.appendChild(summary);

    // 그룹 비었을시 안내, 있으면 클릭가능 항목 제공.
    const list = document.createElement("div");
    list.className = "cho-group-list";
    if (words.length === 0) {
      list.innerHTML = '<div class="cho-group-empty">해당 단어 없음</div>';
    } else {
      words.forEach(w => {
        const item = document.createElement("div");
        item.className = "cho-word-item";
        item.textContent = w.signWordName;
        item.addEventListener("click", () => selectExactWord(w));
        list.appendChild(item);
      });
    }
    details.appendChild(list);
    sidebar.appendChild(details);
  });
}

function selectExactWord(word) {
  document.getElementById("searchInput").value = word.signWordName;
  currentPage = 1;
  renderMainResults([word], word.signWordName + " 검색 결과");
  
  // 서버에 비디오 및 조회수 증가 요청
  fetch(CTX + "/learn/dict/video?word=" + encodeURIComponent(word.signWordName))
    .then(r => r.json())
    .then(updatedVo => {})
    .catch(() => {});
}

/* ─────────────────────────────────────────────
   4) 메인 영역 렌더링
───────────────────────────────────────────── */
function wordCard(w) {
  const card = document.createElement("div");
  card.className = "word-card";
  card.innerHTML =
    '<div class="word-video-wrap">' +
      '<video muted loop playsinline></video>' +
      '<div class="video-unavailable" style="display:none;">영상 준비중</div>' +
    '</div>' +
    '<div class="word-card-name"></div>';

  // 페이지가 https로 서빙되기에 강제 치환(안전 장치)
  let videoUrl = w.signWordVideo || '';
  if (videoUrl.startsWith("http://")) {
    videoUrl = videoUrl.replace("http://", "https://");
  }

  let thumbUrl = w.signWordThumbnail || '';
  if (thumbUrl.startsWith("http://")) {
    thumbUrl = thumbUrl.replace("http://", "https://");
  }

  const wrapEl = card.querySelector(".word-video-wrap");
  const videoEl = card.querySelector("video");
  const fallbackEl = card.querySelector(".video-unavailable");

  // mp4가 아니면(-광처럼 jpg가 잘못 들어간 경우 포함) 영상 자체가 없는 걸로 간주
  const hasVideo = videoUrl.toLowerCase().endsWith(".mp4");

  if (thumbUrl) {
    videoEl.setAttribute("poster", thumbUrl);
  } else {
    wrapEl.classList.add("no-thumb");
  }

  // 애초에 영상이 없으면 호버 전에도 바로 안내 문구 표시
  if (!hasVideo) {
    fallbackEl.style.display = "flex";
  }

  card.querySelector(".word-card-name").textContent = w.signWordName || '';

  // 영상 자체가 로드 실패하면 대체 문구 표시
  videoEl.addEventListener("error", () => {
    if (!videoEl.getAttribute("src")) return;
    videoEl.style.display = "none";
    fallbackEl.style.display = "flex";
  });

  // 영상이 실제로 재생 가능해지면 fallback 숨기고 영상 보이기
  videoEl.addEventListener("loadeddata", () => {
    videoEl.style.display = "block";
    fallbackEl.style.display = "none";
  });

  let hoverTimer = null;
  let isLoaded = false;

  card.addEventListener("mouseenter", () => {
    if (!hasVideo) return; // 영상 없으면 프록시 요청 자체를 안 보냄
    if (isLoaded) {
      videoEl.play().catch(() => {});
      return;
    }

    // 1.5초 마우스 호버시 실행.
    hoverTimer = setTimeout(() => {
      videoEl.src = CTX + "/learn/dict/video-proxy?url=" + encodeURIComponent(videoUrl);
      isLoaded = true;
      videoEl.play().catch(() => {});
    }, 150);
  });

  // 이탈시... 영상타이머 취소 및 일시정지(처음으로)
  card.addEventListener("mouseleave", () => {
    if (hoverTimer) {
      clearTimeout(hoverTimer);
      hoverTimer = null;
    }
    videoEl.pause();
    if (isLoaded) {
      videoEl.currentTime = 0;
    }
  });

  card.addEventListener("click", () => {
    openDetailModal(w);
  });

  return card;
}

// 모달
function openDetailModal(word) {
  const modal = document.getElementById("detailModal");
  const videoEl = document.getElementById("detailVideo");
  const nameEl = document.getElementById("detailWordName");
  const descEl = document.getElementById("detailDescription");
  const metaEl = document.getElementById("detailMeta");

  nameEl.textContent = word.signWordName || '';
  descEl.textContent = word.description || '등록된 설명이 없습니다.';
  metaEl.textContent = `조회 ${updatedVo.viewCount}회`;

  let videoUrl = word.signWordVideo || '';
  if (videoUrl.startsWith("http://")) {
    videoUrl = videoUrl.replace("http://", "https://");
  }

  // 재생속도 버튼 초기 상태 리셋
  videoEl.playbackRate = 1;
  const slowBtn = document.getElementById("detailSlowBtn");
  slowBtn.textContent = "0.5x";
  slowBtn.classList.remove("active");

  videoEl.src = CTX + "/learn/dict/video-proxy?url=" + encodeURIComponent(videoUrl); // 모달 열릴 때 로딩 시작

  modal.showModal();
  videoEl.play().catch(() => {});

  // 관련 단어(같은 초성) 렌더링 + 슬라이드 드로어 초기화(닫힌 상태로)
  renderRelatedWords(word);
  closeSlideDrawer();

  // 영상설명 최신정보 요청
  fetch(CTX + "/learn/dict/video?word=" + encodeURIComponent(word.signWordName))
    .then(r => r.json())
    .then(updatedVo => {
      if (updatedVo && updatedVo.description) {
        descEl.textContent = updatedVo.description;
      }
      if (updatedVo && typeof updatedVo.viewCount === "number") {
        metaEl.textContent = `조회 ${updatedVo.viewCount}회`;
      }
    })
    .catch(() => {});
}

// 재생속도, 다시보기 버튼
document.getElementById("detailSlowBtn").addEventListener("click", () => {
  const videoEl = document.getElementById("detailVideo");
  const btn = document.getElementById("detailSlowBtn");
  if (videoEl.playbackRate === 1) {
    videoEl.playbackRate = 0.5;
    btn.textContent = "1x";
    btn.classList.add("active");
  } else {
    videoEl.playbackRate = 1;
    btn.textContent = "0.5x";
    btn.classList.remove("active");
  }
});

document.getElementById("detailReplayBtn").addEventListener("click", () => {
  const videoEl = document.getElementById("detailVideo");
  videoEl.currentTime = 0;
  videoEl.play().catch(() => {});
});

// 오류신고(기능구현 연결x)
document.getElementById("detailReportBtn").addEventListener("click", () => {
 
  alert("오류 신고 기능은 준비 중입니다.");
});

// 같은 초성의 다른 단어 2개를 관련 단어로 추천 (유튜브 관련영상 리스트 스타일)
function renderRelatedWords(word) {
  const box = document.getElementById("detailRelated");
  box.innerHTML = "";

  const cho = firstChoseongOf(word.signWordName);
  const related = ALL_WORDS
    .filter(w => w.signWordName !== word.signWordName && firstChoseongOf(w.signWordName) === cho)
    .slice(0, 2);

  if (related.length === 0) {
    box.innerHTML = '<div class="cho-group-empty">관련 단어가 없습니다</div>';
    return;
  }

  related.forEach(r => {
    let thumbUrl = r.signWordThumbnail || '';
    if (thumbUrl.startsWith("http://")) {
      thumbUrl = thumbUrl.replace("http://", "https://");
    }

    const item = document.createElement("div");
    item.className = "related-item";
    item.innerHTML =
      '<div class="related-thumb">' +
        (thumbUrl ? '<img src="' + thumbUrl + '" alt="">' : '') +
      '</div>' +
      '<div class="related-info">' +
        '<div class="related-name"></div>' +
        '<div class="related-desc"></div>' +
      '</div>';

    item.querySelector(".related-name").textContent = r.signWordName || '';
    item.querySelector(".related-desc").textContent = r.description || '설명 없음';

    item.addEventListener("click", () => {
      openDetailModal(r); // 관련 단어 클릭 시 그 단어 상세로 전환
    });

    box.appendChild(item);
  });
}

// 모달 닫기 시 src제거 ... 백그라운드에서 영상재생되는거 막기
document.getElementById("detailCloseBtn").addEventListener("click", () => {
  const modal = document.getElementById("detailModal");
  const videoEl = document.getElementById("detailVideo");
  videoEl.pause();
  videoEl.removeAttribute("src"); // 로딩 중단
  videoEl.load();
  closeSlideDrawer();
  modal.close();
});

// 슬라이드 드로어 열기: 모달 실제 렌더링 높이의 2/5를 관련단어 영역 max-height로 지정
function openSlideDrawer() {
  const drawer = document.getElementById("detailSlideDrawer");
  const content = document.getElementById("detailSlideContent");
  const modalInner = document.querySelector(".detail-modal-inner");

  const modalHeight = modalInner.getBoundingClientRect().height;
  const targetHeight = modalHeight * (2 / 5);

  content.style.maxHeight = targetHeight + "px";
  drawer.classList.add("open");

  const toggleBtn = document.getElementById("detailSlideToggle");
  toggleBtn.childNodes[toggleBtn.childNodes.length - 1].textContent = " 관련 단어 접기";
}

// 슬라이드 드로어 닫기
function closeSlideDrawer() {
  const drawer = document.getElementById("detailSlideDrawer");
  const content = document.getElementById("detailSlideContent");

  content.style.maxHeight = "0px";
  drawer.classList.remove("open");

  const toggleBtn = document.getElementById("detailSlideToggle");
  toggleBtn.childNodes[toggleBtn.childNodes.length - 1].textContent = " 관련 단어 보기";
}

// 화살표 버튼 클릭 시 열림/닫힘 토글
document.getElementById("detailSlideToggle").addEventListener("click", () => {
  const drawer = document.getElementById("detailSlideDrawer");
  if (drawer.classList.contains("open")) {
    closeSlideDrawer();
  } else {
    openSlideDrawer();
  }
});

// 카드, 페이지, 라벨 텍스트 정리. 
function renderMainResults(list, label) {
  document.getElementById("mainResultsLabel").textContent = label;
  const container = document.getElementById("mainResults");
  container.innerHTML = "";

  if (!list || list.length === 0) {
    container.innerHTML = '<div class="main-results-empty">일치하는 단어가 없습니다</div>';
    document.getElementById("pagination").innerHTML = "";
    return;
  }

  // 서버에 요청이아닌 가지고 있는 list배열 (slice) 보여주기.
  const totalPages = Math.ceil(list.length / PAGE_SIZE);
  if (currentPage > totalPages) currentPage = 1;
  const start = (currentPage - 1) * PAGE_SIZE;
  const pageItems = list.slice(start, start + PAGE_SIZE);

  pageItems.forEach(w => container.appendChild(wordCard(w)));
  renderPagination(totalPages, list, label);
}

// 페이지 끊기.
function renderPagination(totalPages, list, label) {
  const box = document.getElementById("pagination");
  box.innerHTML = "";
  if (totalPages <= 1) return;

  const BLOCK_SIZE = 5;
  const blockStart = Math.floor((currentPage - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1;
  const blockEnd = Math.min(blockStart + BLOCK_SIZE - 1, totalPages);

  // 이전 블록으로 이동하는 "..."
  if (blockStart > 1) {
    const prevDots = document.createElement("button");
    prevDots.textContent = "...";
    prevDots.className = "page-btn page-dots";
    prevDots.addEventListener("click", () => {
      currentPage = blockStart - BLOCK_SIZE;
      renderMainResults(list, label);
    });
    box.appendChild(prevDots);
  }

  // 현재 블록의 페이지 번호들 (최대 5개)
  for (let p = blockStart; p <= blockEnd; p++) {
    const btn = document.createElement("button");
    btn.textContent = p;
    btn.className = "page-btn" + (p === currentPage ? " active" : "");
    btn.addEventListener("click", () => {
      currentPage = p;
      renderMainResults(list, label);
    });
    box.appendChild(btn);
  }

  // 다음 블록으로 이동하는 "..."
  if (blockEnd < totalPages) {
    const nextDots = document.createElement("button");
    nextDots.textContent = "...";
    nextDots.className = "page-btn page-dots";
    nextDots.addEventListener("click", () => {
      currentPage = blockEnd + 1;
      renderMainResults(list, label);
    });
    box.appendChild(nextDots);
  }
}

// 처음 페이지 조회시 랜덤 6개 추출
// xml에서 한번에 처리시 api 2번호출(사이드바, sql조회) >> db과부하
function showRandomSix() {
  const shuffled = [...ALL_WORDS].sort(() => Math.random() - 0.5); // 배열복사(원본 훼손 방지)
  renderMainResults(shuffled.slice(0, 6), "오늘의 추천 단어");
}

// 검색 창 비어있을 시 다시 랜덤
function runSearch() {
  const keyword = document.getElementById("searchInput").value.trim();
  if (!keyword) {
    showRandomSix();
    return;
  }
  const filtered = ALL_WORDS.filter(w => matchesQuery(w.signWordName, keyword));
  currentPage = 1;
  renderMainResults(filtered, `"${keyword}" 검색 결과 (${filtered.length}개)`);
}

document.getElementById("searchInput").addEventListener("input", runSearch);
document.getElementById("searchBtn").addEventListener("click", runSearch);
document.getElementById("searchInput").addEventListener("keydown", (e) => {
  if (e.key === "Enter") runSearch();
});



/* ─────────────────────────────────────────────
   6) 초기 진입
───────────────────────────────────────────── */
loadAllWords().then(() => {
  renderChoSidebar();
  showRandomSix();
});
</script>

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