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
  .main-results { display:grid; grid-template-columns:repeat(3, 1fr); gap:14px; max-height:640px; overflow-y:auto; padding-right:4px; }
  .word-card { border:1px solid #eee; border-radius:14px; overflow:hidden; background:#fafafa; cursor:pointer; }
  .word-card video { width:100%; aspect-ratio:4/3; object-fit:cover; background:#000; display:block; }
  .word-card-name { padding:8px 10px; font-weight:800; font-size:14px; }
  .main-results-empty { padding:24px; color:var(--text-sub); font-size:14px; }

  /* 수어 인식 모달 */
  .cam-modal { border:none; border-radius:20px; padding:0; max-width:480px; width:92vw; max-height:85vh; }
  .cam-modal::backdrop { background:rgba(0,0,0,.55); }
  .cam-modal-inner { padding:20px; position:relative; max-height:85vh; overflow-y:auto; }
  .cam-modal-title { font-weight:800; font-size:16px; margin-bottom:12px; }
  .cam-modal-close { position:absolute; top:14px; right:14px; border:none; background:none; font-size:20px; cursor:pointer; line-height:1; }
  .cam-wrap { position:relative; width:100%; aspect-ratio:4/3; margin:0 auto; border-radius:12px; overflow:hidden; background:#000; }
  .cam-wrap video, .cam-wrap canvas { position:absolute; top:0; left:0; width:100%; height:100%; object-fit:cover; transform:scaleX(-1); }
  .cam-result { font-size:26px; font-weight:800; text-align:center; margin:14px 0; min-height:36px; }
  .cam-modal-btns { display:flex; gap:8px; justify-content:center; }
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
      <video id="video" autoplay playsinline muted></video>
      <canvas id="canvas"></canvas>
    </div>
    <div class="cam-result" id="result">-</div>
    <div class="cam-modal-btns">
      <button class="btn btn-primary btn-sm" id="camSearchBtn">이 단어로 검색</button>
      <button class="btn btn-ghost btn-sm" id="camResetBtn">초기화</button>
    </div>
  </div>
</dialog>

<script>
const CTX = "${pageContext.request.contextPath}";
let ALL_WORDS = [];

/* ─────────────────────────────────────────────
   1) 전체 단어 로드 (서버가 직접 JSON 직렬화 -> 수동 조립 안 함)
───────────────────────────────────────────── */
function loadAllWords() {
  return fetch(CTX + "/learn/dict/search")
    .then(r => r.json())
    .then(list => { ALL_WORDS = list; });
}

/* ─────────────────────────────────────────────
   2) 한글 초성 유틸
───────────────────────────────────────────── */
const CHO = ['ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ','ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
const JUNG = ['ㅏ','ㅐ','ㅑ','ㅒ','ㅓ','ㅔ','ㅕ','ㅖ','ㅗ','ㅘ','ㅙ','ㅚ','ㅛ','ㅜ','ㅝ','ㅞ','ㅟ','ㅠ','ㅡ','ㅢ','ㅣ'];
const JONG = ['', 'ㄱ','ㄲ','ㄳ','ㄴ','ㄵ','ㄶ','ㄷ','ㄹ','ㄺ','ㄻ','ㄼ','ㄽ','ㄾ','ㄿ','ㅀ','ㅁ','ㅂ','ㅄ','ㅅ','ㅆ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
const BASIC_CHO = ['ㄱ','ㄴ','ㄷ','ㄹ','ㅁ','ㅂ','ㅅ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];

// 단어 안 모든 음절의 초성 배열 (검색/필터용)
function choseongListOf(word) {
  const result = [];
  for (const ch of word) {
    const code = ch.charCodeAt(0) - 0xAC00;
    if (code >= 0 && code <= 11171) {
      result.push(CHO[Math.floor(code / (21 * 28))]);
    }
  }
  return result;
}

// 첫 글자 초성 (사전 그룹핑용)
function firstChoseongOf(word) {
  const list = choseongListOf(word);
  return list.length ? list[0] : null;
}

function matchesQuery(name, keyword) {
  if (!keyword) return true;
  if (keyword.length === 1 && CHO.includes(keyword)) {
    return choseongListOf(name).includes(keyword);
  }
  return name.includes(keyword);
}

/* ─────────────────────────────────────────────
   3) 좌측 초성 아코디언 렌더링
───────────────────────────────────────────── */
function renderChoSidebar() {
  const sidebar = document.getElementById("choSidebar");
  sidebar.querySelectorAll(".cho-group").forEach(el => el.remove());

  const groups = {};
  BASIC_CHO.forEach(c => groups[c] = []);
  groups["기타"] = [];

  ALL_WORDS.forEach(w => {
    const cho = firstChoseongOf(w.signWordName);
    if (BASIC_CHO.includes(cho)) groups[cho].push(w);
    else groups["기타"].push(w);
  });

  [...BASIC_CHO, "기타"].forEach(cho => {
    const words = groups[cho].sort((a, b) => a.signWordName.localeCompare(b.signWordName, "ko"));
    if (cho === "기타" && words.length === 0) return; // 기타 그룹은 내용 없으면 생략

    const details = document.createElement("details");
    details.className = "cho-group";

    const summary = document.createElement("summary");
    summary.innerHTML = "<span>" + cho + "</span><span class=\"cho-count\">" + words.length + "</span>";
    details.appendChild(summary);

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
  renderMainResults([word], word.signWordName + " 검색 결과");
  fetch(CTX + "/learn/dict/video?word=" + encodeURIComponent(word.signWordName)).catch(() => {});
}

/* ─────────────────────────────────────────────
   4) 메인 영역 렌더링 (첫 화면 랜덤 6개 / 검색 결과)
───────────────────────────────────────────── */
function wordCard(w) {
  const card = document.createElement("div");
  card.className = "word-card";
  card.innerHTML =
    '<video autoplay muted loop playsinline></video>' +
    '<div class="word-card-name"></div>';
  card.querySelector("video").src = w.signWordVideo;
  card.querySelector(".word-card-name").textContent = w.signWordName;
  card.addEventListener("click", () => {
    fetch(CTX + "/learn/dict/video?word=" + encodeURIComponent(w.signWordName)).catch(() => {});
  });
  return card;
}

function renderMainResults(list, label) {
  document.getElementById("mainResultsLabel").textContent = label;
  const container = document.getElementById("mainResults");
  container.innerHTML = "";
  if (list.length === 0) {
    container.innerHTML = '<div class="main-results-empty">일치하는 단어가 없어요</div>';
    return;
  }
  list.forEach(w => container.appendChild(wordCard(w)));
}

function showRandomSix() {
  const shuffled = [...ALL_WORDS].sort(() => Math.random() - 0.5);
  renderMainResults(shuffled.slice(0, 6), "오늘의 추천 단어");
}

function runSearch() {
  const keyword = document.getElementById("searchInput").value.trim();
  if (!keyword) {
    showRandomSix();
    return;
  }
  const filtered = ALL_WORDS.filter(w => matchesQuery(w.signWordName, keyword));
  renderMainResults(filtered, `"${keyword}" 검색 결과 (${filtered.length}개)`);
}

document.getElementById("searchInput").addEventListener("input", runSearch);
document.getElementById("searchBtn").addEventListener("click", runSearch);
document.getElementById("searchInput").addEventListener("keydown", (e) => {
  if (e.key === "Enter") runSearch();
});

/* ─────────────────────────────────────────────
   5) 자모 자동 조합기 (2벌식 조합 규칙)
───────────────────────────────────────────── */
function isVowel(t) { return JUNG.indexOf(t) !== -1; }
function isConsonant(t) { return CHO.indexOf(t) !== -1; }
function isValidJong(t) { return JONG.indexOf(t) !== -1 && t !== ''; }

let composer = { cho: null, jung: null, jong: null };
let committedWord = "";

function combine(cho, jung, jong) {
  if (cho === null || jung === null) return null;
  const c = CHO.indexOf(cho);
  const j = JUNG.indexOf(jung);
  const f = jong ? JONG.indexOf(jong) : 0;
  if (c < 0 || j < 0 || f < 0) return null;
  return String.fromCharCode(0xAC00 + (c * 21 + j) * 28 + f);
}

function commitCurrent() {
  const ch = combine(composer.cho, composer.jung, composer.jong);
  if (ch) committedWord += ch;
}

function renderComposed() {
  const partial = combine(composer.cho, composer.jung, composer.jong) || (composer.cho || "");
  document.getElementById("result").textContent = (committedWord + (partial || "")) || "-";
}

function resetComposer() {
  composer = { cho: null, jung: null, jong: null };
  committedWord = "";
  renderComposed();
}

function feedJamo(token) {
  if (isVowel(token)) {
    if (composer.cho === null) return;
    if (composer.jung === null) {
      composer.jung = token;
    } else if (composer.jong === null) {
      return;
    } else {
      const givenBack = composer.jong;
      composer.jong = null;
      commitCurrent();
      composer = { cho: givenBack, jung: token, jong: null };
    }
  } else if (isConsonant(token)) {
    if (composer.cho === null) {
      composer.cho = token;
    } else if (composer.jung === null) {
      composer.cho = token;
    } else if (composer.jong === null) {
      if (isValidJong(token)) {
        composer.jong = token;
      } else {
        commitCurrent();
        composer = { cho: token, jung: null, jong: null };
      }
    } else {
      commitCurrent();
      composer = { cho: token, jung: null, jong: null };
    }
  }
  renderComposed();
}

document.getElementById("camResetBtn").addEventListener("click", resetComposer);

document.getElementById("camSearchBtn").addEventListener("click", () => {
  commitCurrent();
  const word = committedWord;
  if (!word) return;
  document.getElementById("searchInput").value = word;
  document.getElementById("camModal").close();
  cam.stop();
  runSearch();
});

/* ─────────────────────────────────────────────
   6) 초기 진입
───────────────────────────────────────────── */
loadAllWords().then(() => {
  renderChoSidebar();
  showRandomSix();
});
</script>

<!-- 수어 인식: python-server가 제공하는 완제품 위젯 그대로 사용 -->
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
      feedJamo(result.label);
    },
  });

  document.getElementById("camToggleBtn").addEventListener("click", async () => {
    resetComposer();
    document.getElementById("camModal").showModal();
    await cam.start();
  });

  document.getElementById("camCloseBtn").addEventListener("click", () => {
    document.getElementById("camModal").close();
    cam.stop();
  });

  window.cam = cam; // camSearchBtn 리스너에서 stop() 호출용
</script>

</body>
</html>