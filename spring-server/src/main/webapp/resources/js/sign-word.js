let ALL_WORDS = [];
let currentPage = 1;
const PAGE_SIZE = 6;

// 상세모달 이전/이후 이동용 히스토리 - 열었던 단어들을 순서대로 쌓음
let detailHistory = [];
let detailHistoryIndex = -1;

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
// fromHistory=true면 이전/이후 버튼으로 이동한 경우라 히스토리에 새로 안쌓고 그대로 재생만 함
function openDetailModal(word, fromHistory) {
  const modal = document.getElementById("detailModal");
  const videoEl = document.getElementById("detailVideo");
  const nameEl = document.getElementById("detailWordName");
  const descEl = document.getElementById("detailDescription");

  if (!fromHistory) {
    // 히스토리 중간에서 새단어(관련단어 클릭 등) 열면 그 뒤 기록은 버리고 새로 이어붙임
    detailHistory = detailHistory.slice(0, detailHistoryIndex + 1);
    detailHistory.push(word);
    detailHistoryIndex = detailHistory.length - 1;
  }
  updateDetailNavButtons();

  nameEl.textContent = word.signWordName || '';
  currentDetailWord = word.signWordName;
  descEl.textContent = word.description || '등록된 설명이 없습니다.';
  // 조회수 안뜨던 문제 - fetch 응답 기다리기 전에 일단 목록에서 이미 갖고있는 viewCount로 먼저 채워놓음
  // (fetch 끝나면 밑에서 최신값으로 다시 덮어씀. word.viewCount 없으면 일단 빈칸)
  console.log("word 객체 확인:", word); // viewCount 필드가 실제로 있는지 여기서 확인


  let videoUrl = word.signWordVideo || '';
  if (videoUrl.startsWith("http://")) {
    videoUrl = videoUrl.replace("http://", "https://");
  }

  // 재생속도 버튼 초기 상태 리셋
  // 재생속도 슬라이더 초기 상태 리셋 (index 3 = 1x)
  videoEl.playbackRate = 1;
  document.getElementById("detailSpeedSlider").value = 3;
  document.getElementById("detailSpeedLabel").textContent = "1x";

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
      
    })
    .catch(() => {});
}

// 재생속도, 다시보기 버튼
const SPEED_STEPS = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

document.getElementById("detailSpeedSlider").addEventListener("input", (e) => {
  const videoEl = document.getElementById("detailVideo");
  const speed = SPEED_STEPS[parseInt(e.target.value, 10)];
  videoEl.playbackRate = speed;
  document.getElementById("detailSpeedLabel").textContent = speed + "x";
});

document.getElementById("detailReplayBtn").addEventListener("click", () => {
  const videoEl = document.getElementById("detailVideo");
  videoEl.currentTime = 0;
  videoEl.play().catch(() => {});
});

// 현재 상세모달에 열려있는 단어 추적 (신고 시 word 파라미터로 사용)
let currentDetailWord = null;

// 오류신고
document.getElementById("detailReportBtn").addEventListener("click", () => {
  if (!currentDetailWord) return;

  const reason = prompt("신고 사유를 입력해주세요 (선택사항)");
  if (reason === null) return; // 취소시 전송 안함

  const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;

  const headers = { "Content-Type": "application/x-www-form-urlencoded" };
  if (csrfToken && csrfHeader) {
    headers[csrfHeader] = csrfToken;
  }

  fetch(CTX + "/learn/dict/report", {
    method: "POST",
    headers: headers,
    body: "word=" + encodeURIComponent(currentDetailWord) +
          "&content=" + encodeURIComponent(reason || "")
  })
    .then(r => r.json())
    .then(res => {
      if (res.success) {
        alert("신고가 접수되었습니다.");
      } else {
        alert(res.message || "신고 접수에 실패했습니다.");
      }
    })
    .catch(() => alert("신고 접수 중 오류가 발생했습니다."));
});

// 이전 단어로 이동 - 히스토리 인덱스만 앞으로 옮기고 fromHistory=true로 재오픈(중복기록 방지)
function goDetailPrev() {
  if (detailHistoryIndex <= 0) return;
  detailHistoryIndex--;
  openDetailModal(detailHistory[detailHistoryIndex], true);
}

// 이후 단어로 이동
function goDetailNext() {
  if (detailHistoryIndex >= detailHistory.length - 1) return;
  detailHistoryIndex++;
  openDetailModal(detailHistory[detailHistoryIndex], true);
}

// 이전/이후 없으면 버튼 자체를 숨김
function updateDetailNavButtons() {
  document.getElementById("detailPrevBtn").style.display = detailHistoryIndex > 0 ? "flex" : "none";
  document.getElementById("detailNextBtn").style.display = detailHistoryIndex < detailHistory.length - 1 ? "flex" : "none";
}

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

document.getElementById("detailPrevBtn").addEventListener("click", goDetailPrev);
document.getElementById("detailNextBtn").addEventListener("click", goDetailNext);

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

// 슬라이드 드로어 열기 - 이제 CSS가 알아서 60%까지 슬라이드업 해주니까 높이 계산 로직 필요없어짐, 클래스 토글만
function openSlideDrawer() {
  const drawer = document.getElementById("detailSlideDrawer");
  drawer.classList.add("open");

  const toggleBtn = document.getElementById("detailSlideToggle");
  toggleBtn.childNodes[toggleBtn.childNodes.length - 1].textContent = " 접기";
}

// 슬라이드 드로어 닫기
function closeSlideDrawer() {
  const drawer = document.getElementById("detailSlideDrawer");
  drawer.classList.remove("open");

  const toggleBtn = document.getElementById("detailSlideToggle");
  toggleBtn.childNodes[toggleBtn.childNodes.length - 1].textContent = " 다른 단어 보기";
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