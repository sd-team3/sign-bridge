let ALL_WORDS = [];
let FAVORITE_IDS = new Set();
let currentPage = 1;
const PAGE_SIZE = 6;


let detailHistory = [];
let detailHistoryIndex = -1;




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




const CHO = ['ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ','ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
const JUNG = ['ㅏ','ㅐ','ㅑ','ㅒ','ㅓ','ㅔ','ㅕ','ㅖ','ㅗ','ㅘ','ㅙ','ㅚ','ㅛ','ㅜ','ㅝ','ㅞ','ㅟ','ㅠ','ㅡ','ㅢ','ㅣ'];
const JONG = ['', 'ㄱ','ㄲ','ㄳ','ㄴ','ㄵ','ㄶ','ㄷ','ㄹ','ㄺ','ㄻ','ㄼ','ㄽ','ㄾ','ㄿ','ㅀ','ㅁ','ㅂ','ㅄ','ㅅ','ㅆ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
const BASIC_CHO = ['ㄱ','ㄴ','ㄷ','ㄹ','ㅁ','ㅂ','ㅅ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];


function isConsonantJamo(ch) {
  const code = ch.charCodeAt(0);
  return code >= 0x3131 && code <= 0x314E;
}
function isVowelJamo(ch) {
  const code = ch.charCodeAt(0);
  return code >= 0x314F && code <= 0x3163;
}


function choseongListOf(word) {
  const result = [];
  if (!word) return result;
  for (const ch of word) {
    const code = ch.charCodeAt(0) - 0xAC00;
    if (code >= 0 && code <= 11171) {
      result.push(CHO[Math.floor(code / (21 * 28))]);
    } else if (isConsonantJamo(ch)) {

      result.push(ch);
    }
  }
  return result;
}


function firstChoseongOf(word) {
  const list = choseongListOf(word);
  return list.length ? list[0] : null;
}


function startsWithParenthesis(word) {
  return /^[(（]/.test(word);
}



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


function choseongOfChar(ch) {
  const code = ch.charCodeAt(0) - 0xAC00;
  if (code >= 0 && code <= 11171) {
    return CHO[Math.floor(code / (21 * 28))];
  }
  if (isConsonantJamo(ch)) return ch;
  return null;
}




function charMatches(nameCh, keyCh) {
  if (isConsonantJamo(keyCh)) {
    return choseongOfChar(nameCh) === keyCh;
  }
  return nameCh === keyCh;
}



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


function matchesQuery(name, keyword) {
  if (!keyword) return true;
  if (!name) return false;
  return matchesSequential(name, keyword);
}




function renderChoSidebar() {
  const sidebar = document.getElementById("choSidebar");
  if (!sidebar) return;
  sidebar.querySelectorAll(".cho-group").forEach(el => el.remove());


  const groupKeys = [...CHO, "모음", "기타"];
  const groups = {};
  groupKeys.forEach(k => groups[k] = []);



  ALL_WORDS.forEach(w => {
    const keys = classifyGroups(w.signWordName);
    keys.forEach(key => {
      (groups[key] || groups["기타"]).push(w);
    });
  });


  groupKeys.forEach(key => {
    const words = groups[key].sort((a, b) => a.signWordName.localeCompare(b.signWordName, "ko"));

    if (words.length === 0 && (key === "기타" || key === "모음")) return;

    const details = document.createElement("details");
    details.className = "cho-group";


    const summary = document.createElement("summary");
    summary.innerHTML = "<span>" + key + "</span><span class=\"cho-count\">" + words.length + "</span>";
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
  currentPage = 1;
  renderMainResults([word], word.signWordName + " 검색 결과");
  

  fetch(CTX + "/learn/dict/video?word=" + encodeURIComponent(word.signWordName))
    .then(r => r.json())
    .then(updatedVo => {})
    .catch(() => {});
}




function wordCard(w) {
  const card = document.createElement("div");
  card.className = "word-card";
  card.innerHTML =
      '<div class="word-video-wrap">' +
        '<button type="button" class="fav-star" data-word-id="' + w.signWordId + '">☆</button>' +
        '<video muted loop playsinline></video>' +
        '<div class="video-unavailable" style="display:none;">영상 준비중</div>' +
      '</div>' +
      '<div class="word-card-name"></div>';


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


  const hasVideo = videoUrl.toLowerCase().endsWith(".mp4");

  if (thumbUrl) {
    videoEl.setAttribute("poster", thumbUrl);
  } else {
    wrapEl.classList.add("no-thumb");
  }


  if (!hasVideo) {
    fallbackEl.style.display = "flex";
  }

  card.querySelector(".word-card-name").textContent = w.signWordName || '';


  videoEl.addEventListener("error", () => {
    if (!videoEl.getAttribute("src")) return;
    videoEl.style.display = "none";
    fallbackEl.style.display = "flex";
  });


  videoEl.addEventListener("loadeddata", () => {
    videoEl.style.display = "block";
    fallbackEl.style.display = "none";
  });

  let hoverTimer = null;
  let isLoaded = false;

  card.addEventListener("mouseenter", () => {
    if (!hasVideo) return;
    if (isLoaded) {
      videoEl.play().catch(() => {});
      return;
    }


    hoverTimer = setTimeout(() => {
      videoEl.src = CTX + "/learn/dict/video-proxy?url=" + encodeURIComponent(videoUrl);
      isLoaded = true;
      videoEl.play().catch(() => {});
    }, 150);
  });


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

  const starEl = card.querySelector(".fav-star");
  if (FAVORITE_IDS.has(w.signWordId)) {
    starEl.textContent = "★";
    starEl.classList.add("active");
  }
  starEl.addEventListener("click", (e) => {
    e.stopPropagation();
    toggleFavorite(w.signWordId, starEl);
  });

  return card;
}


function resizeDetailVideo() {
  const modal = document.getElementById("detailModal");
  if (!modal.open) return;
  const content = modal.querySelector(".detail-scroll-content");
  const panel = modal.querySelector(".detail-demo-panel");
  const video = document.getElementById("detailVideo");
  const ratio = video.videoWidth && video.videoHeight ? video.videoWidth / video.videoHeight : 4 / 3;
  const style = getComputedStyle(panel);
  const blocks = [...panel.children].filter(el => !el.classList.contains("detail-video-row") && getComputedStyle(el).position !== "absolute");
  const extra = blocks.reduce((height, el) => height + el.getBoundingClientRect().height, 0) + blocks.length * parseFloat(style.rowGap);
  const section = modal.querySelector(".detail-description-section");
  const sectionStyle = getComputedStyle(section);
  const descriptionSpace = parseFloat(sectionStyle.marginTop) + parseFloat(sectionStyle.paddingTop) + 1 + section.querySelector("h3").getBoundingClientRect().height + 12 + 90;
  const available = content.clientHeight - parseFloat(getComputedStyle(content).paddingBottom);
  const width = Math.min(panel.clientWidth, 420);
  const height = Math.max(40, Math.min(width / ratio, available - descriptionSpace - extra));
  modal.style.setProperty("--detail-top-height", `${height + extra}px`);
  modal.style.setProperty("--detail-video-width", `${Math.min(width, height * ratio)}px`);
}

const detailVideoElement = document.getElementById("detailVideo");
detailVideoElement.addEventListener("loadedmetadata", resizeDetailVideo);
new ResizeObserver(resizeDetailVideo).observe(document.querySelector("#detailModal .detail-scroll-content"));


function openDetailModal(word, fromHistory) {
  const modal = document.getElementById("detailModal");
  const videoEl = document.getElementById("detailVideo");
  const nameEl = document.getElementById("detailWordName");
  const favBtn = document.getElementById("detailFavStar");
  favBtn.dataset.wordId = word.signWordId;
  favBtn.textContent = FAVORITE_IDS.has(word.signWordId) ? "★" : "☆";
  favBtn.classList.toggle("active", FAVORITE_IDS.has(word.signWordId));
  favBtn.onclick = () => toggleFavorite(word.signWordId, favBtn);
  const descEl = document.getElementById("detailDescription");



  if (!fromHistory) {

    detailHistory = detailHistory.slice(0, detailHistoryIndex + 1);
    detailHistory.push(word);
    detailHistoryIndex = detailHistory.length - 1;
  }
  updateDetailNavButtons();

  nameEl.textContent = word.signWordName || '';
  currentDetailWord = word.signWordName;
  descEl.textContent = word.description || '등록된 설명이 없습니다.';


  console.log("word 객체 확인:", word);


  let videoUrl = word.signWordVideo || '';
  if (videoUrl.startsWith("http://")) {
    videoUrl = videoUrl.replace("http://", "https://");
  }



  videoEl.playbackRate = 1;
  document.getElementById("detailSpeedSlider").value = 3;
  document.getElementById("detailSpeedLabel").textContent = "1x";

  videoEl.src = CTX + "/learn/dict/video-proxy?url=" + encodeURIComponent(videoUrl);

  modal.showModal();
  modal.querySelector(".detail-scroll-content").scrollTop = 0;
  videoEl.play().catch(() => {});


  renderRelatedWords(word);
  resizeDetailVideo();


  fetch(CTX + "/learn/dict/video?word=" + encodeURIComponent(word.signWordName))
    .then(r => r.json())
    .then(updatedVo => {
      if (updatedVo && updatedVo.description) {
        descEl.textContent = updatedVo.description;
      }
      
    })
    .catch(() => {});
}


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


let currentDetailWord = null;


document.getElementById("detailReportBtn").addEventListener("click", () => {
  if (!currentDetailWord) return;

  document.getElementById("reportTargetWord").innerHTML = "대상 단어: <b>" + currentDetailWord + "</b>";
  document.getElementById("reportReasonInput").value = "";

  document.getElementById("reportCategorySelect").selectedIndex = 0;
  document.getElementById("reportModal").showModal();
});


function showReportStatus(success, message) {
  const iconEl = document.getElementById("reportStatusIcon");
  const msgEl = document.getElementById("reportStatusMsg");
  iconEl.textContent = success ? "✓" : "!";
  iconEl.className = "report-status-icon" + (success ? "" : " error");
  msgEl.textContent = message;
  document.getElementById("reportStatusModal").showModal();
}
document.getElementById("reportStatusOkBtn").addEventListener("click", () => {
  document.getElementById("reportStatusModal").close();
});


function closeReportModal() {
  document.getElementById("reportModal").close();
}
document.getElementById("reportCancelBtn").addEventListener("click", closeReportModal);
document.getElementById("reportCloseBtn").addEventListener("click", closeReportModal);


document.getElementById("reportSubmitBtn").addEventListener("click", () => {
  if (!currentDetailWord) return;

  const reason = document.getElementById("reportReasonInput").value.trim();
  const category = document.getElementById("reportCategorySelect").value;
  const submitBtn = document.getElementById("reportSubmitBtn");

  const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;

  const headers = { "Content-Type": "application/x-www-form-urlencoded" };
  if (csrfToken && csrfHeader) {
    headers[csrfHeader] = csrfToken;
  }

  submitBtn.disabled = true;
  fetch(CTX + "/learn/dict/report", {
    method: "POST",
    headers: headers,
    body: "word=" + encodeURIComponent(currentDetailWord) +
          "&category=" + encodeURIComponent(category) +
          "&content=" + encodeURIComponent(reason)
  })
    .then(r => r.json())
    .then(res => {
      if (res.success) {
        closeReportModal();
        showReportStatus(true, "신고가 접수되었습니다.");
      } else {
        showReportStatus(false, res.message || "신고 접수에 실패했습니다.");
      }
    })
    .catch(() => showReportStatus(false, "신고 접수 중 오류가 발생했습니다."))
    .finally(() => { submitBtn.disabled = false; });
});


function goDetailPrev() {
  if (detailHistoryIndex <= 0) return;
  detailHistoryIndex--;
  openDetailModal(detailHistory[detailHistoryIndex], true);
}


function goDetailNext() {
  if (detailHistoryIndex >= detailHistory.length - 1) return;
  detailHistoryIndex++;
  openDetailModal(detailHistory[detailHistoryIndex], true);
}


function updateDetailNavButtons() {
  document.getElementById("detailPrevBtn").style.display = detailHistoryIndex > 0 ? "flex" : "none";
  document.getElementById("detailNextBtn").style.display = detailHistoryIndex < detailHistory.length - 1 ? "flex" : "none";
}


function renderRelatedWords(word) {
  const box = document.getElementById("detailRelated");
  box.innerHTML = "";


  const pool = ALL_WORDS.filter(w => w.signWordName !== word.signWordName);
  const related = [...pool].sort(() => Math.random() - 0.5).slice(0, 4);

  if (related.length === 0) {
    box.innerHTML = '<div class="cho-group-empty">더이상 단어가 없습니다</div>';
    return;
  }

  related.forEach(r => {
    const item = document.createElement("button");
    item.type = "button";
    item.className = "related-item";
    item.title = r.signWordName || '';
    const thumbnail = document.createElement("span");
    thumbnail.className = "related-thumb";
    thumbnail.setAttribute("aria-hidden", "true");
    let thumbUrl = r.signWordThumbnail || '';
    if (thumbUrl.startsWith("http://")) thumbUrl = thumbUrl.replace("http://", "https://");
    if (thumbUrl) {
      const image = document.createElement("img");
      image.src = thumbUrl;
      image.alt = '';
      image.loading = "lazy";
      image.decoding = "async";
      image.addEventListener("error", () => { image.remove(); thumbnail.classList.add("unavailable"); });
      thumbnail.appendChild(image);
    } else thumbnail.classList.add("unavailable");
    const name = document.createElement("span");
    name.className = "related-name";
    name.textContent = r.signWordName || '';
    item.append(thumbnail, name);

    item.addEventListener("click", () => {
      openDetailModal(r);
    });

    box.appendChild(item);
  });
}

document.getElementById("detailPrevBtn").addEventListener("click", goDetailPrev);
document.getElementById("detailNextBtn").addEventListener("click", goDetailNext);


document.getElementById("detailCloseBtn").addEventListener("click", () => {
  const modal = document.getElementById("detailModal");
  const videoEl = document.getElementById("detailVideo");
  videoEl.pause();
  videoEl.removeAttribute("src");
  videoEl.load();
  modal.close();
});


function renderMainResults(list, label) {
  document.getElementById("mainResultsLabel").textContent = label;
  const container = document.getElementById("mainResults");
  container.innerHTML = "";

  if (!list || list.length === 0) {
    container.innerHTML = '<div class="main-results-empty">일치하는 단어가 없습니다</div>';
    document.getElementById("pagination").innerHTML = "";
    return;
  }


  const totalPages = Math.ceil(list.length / PAGE_SIZE);
  if (currentPage > totalPages) currentPage = 1;
  const start = (currentPage - 1) * PAGE_SIZE;
  const pageItems = list.slice(start, start + PAGE_SIZE);

  pageItems.forEach(w => container.appendChild(wordCard(w)));
  renderPagination(totalPages, list, label);
}


function renderPagination(totalPages, list, label) {
  const box = document.getElementById("pagination");
  box.innerHTML = "";
  if (totalPages <= 1) return;

  const BLOCK_SIZE = 5;
  const blockStart = Math.floor((currentPage - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1;
  const blockEnd = Math.min(blockStart + BLOCK_SIZE - 1, totalPages);


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
  currentPage = 1;
  renderMainResults(filtered, `"${keyword}" 검색 결과 (${filtered.length}개)`);
}

document.getElementById("searchInput").addEventListener("input", runSearch);
document.getElementById("searchBtn").addEventListener("click", runSearch);
document.getElementById("searchInput").addEventListener("keydown", (e) => {
  if (e.key === "Enter") runSearch();
});

function loadFavoriteIds() {
  return fetch(CTX + "/member/favorite/ids")
    .then(r => r.json())
    .then(data => { if (data.success) FAVORITE_IDS = new Set(data.ids); })
    .catch(() => {});
}

function toggleFavorite(signWordId, starEl) {
  const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
  const headers = { "Content-Type": "application/x-www-form-urlencoded" };
  if (csrfToken && csrfHeader) headers[csrfHeader] = csrfToken;

  fetch(CTX + "/member/favorite/toggle", {
    method: "POST",
    headers: headers,
    body: "signWordId=" + encodeURIComponent(signWordId)
  })
    .then(r => r.json())
    .then(data => {
      if (!data.success) { alert(data.message || "로그인이 필요합니다."); return; }
      if (data.favorited) FAVORITE_IDS.add(signWordId);
      else FAVORITE_IDS.delete(signWordId);

      document.querySelectorAll('.fav-star[data-word-id="' + signWordId + '"]').forEach(el => {
        el.textContent = data.favorited ? "★" : "☆";
        el.classList.toggle("active", data.favorited);
      });
    })
    .catch(() => alert("즐겨찾기 처리 중 오류가 발생했습니다."));
}






Promise.all([loadAllWords(), loadFavoriteIds()]).then(() => {
  renderChoSidebar();


  const params = new URLSearchParams(location.search);
  const targetWordName = params.get("word");

  if (targetWordName) {
    const target = ALL_WORDS.find(w => w.signWordName === targetWordName);
    showRandomSix();
    if (target) openDetailModal(target);
  } else {
    showRandomSix();
  }
});