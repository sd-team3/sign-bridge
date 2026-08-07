const loadedTabs = { myposts: false, mycomments: false };
const filterState = { myposts: '', mycomments: '' };
const categoryLabel = { FREE: '자유', QNA: '질문', INFO: '정보', REPORT: '신고', NOTICE: '공지' };

function mpTab(name) {
  if (name === 'mycontent' && !loadedTabs.myposts) loadMyPosts(1);
  if (name === 'wronganswer' && !loadedTabs.wronganswer) loadWrongAnswers(1);
  if (name === 'learninghistory' && !loadedTabs.jamohistory) loadJamoHistory(1);
  document.querySelectorAll('.mp-tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('.mp-panel').forEach(p => p.classList.toggle('active', p.id === 'mp-panel-' + name));
}

function lhSubTab(name) {
  document.querySelectorAll('#mp-panel-learninghistory .mp-subtab').forEach(t => t.classList.toggle('active', t.dataset.subtab === name));
  document.querySelectorAll('#mp-panel-learninghistory .mp-subpanel').forEach(p => p.classList.toggle('active', p.id === 'mp-subpanel-' + name));
  if (name === 'jamo' && !loadedTabs.jamohistory) loadJamoHistory(1);
  if (name === 'word' && !loadedTabs.wordhistory) loadWordHistory(1);
}

function mcSubTab(name) {
  document.querySelectorAll('#mp-panel-mycontent .mp-subtab').forEach(t => t.classList.toggle('active', t.dataset.subtab === name));
  document.querySelectorAll('#mp-panel-mycontent .mp-subpanel').forEach(p => p.classList.toggle('active', p.id === 'mp-subpanel-' + name));
  if (name === 'myposts' && !loadedTabs.myposts) loadMyPosts(1);
  if (name === 'mycomments' && !loadedTabs.mycomments) loadMyComments(1);
}

function loadMyPosts(page) {
    fetch(`/member/mypage/board?page=${page}&category=${filterState.myposts}`)
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;
            loadedTabs.myposts = true;
            const wrap = document.querySelector('#mp-subpanel-myposts .mp-list-wrap');
            wrap.innerHTML = data.boards.length ? data.boards.map(b => `
                <div class="mp-post-row">
                    <a class="mp-post-row-title" href="/board/info?boardId=${b.boardId}">${b.boardTitle}</a>
                    <span class="mp-post-row-cat">${categoryLabel[b.categoryIdx] || b.categoryIdx}</span>
                    <span class="mp-post-row-cnt">${b.commentCnt}</span>
                    <span class="mp-post-row-date">${formatDate(b.regDate)}</span>
                </div>
            `).join('') : '<div class="mp-list-empty">작성한 게시글이 없습니다.</div>';
            renderPagination('#mp-subpanel-myposts .pagination', data.currentPage, data.totalPages, loadMyPosts);
        });
}

function loadMyComments(page) {
    fetch(`/member/mypage/comment?page=${page}&category=${filterState.mycomments}`)
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;
            loadedTabs.mycomments = true;
            const wrap = document.querySelector('#mp-subpanel-mycomments .mp-list-wrap');
            wrap.innerHTML = data.comments.length ? data.comments.map(c => `
                <div class="mp-comment-row">
                    <span class="mp-comment-row-content">${c.commentContent}</span>
                    <span class="mp-comment-row-reply">${c.replyCnt}</span>
                    <a class="mp-comment-row-board" href="/board/info?boardId=${c.boardId}">${c.boardTitle}</a>
                </div>
            `).join('') : '<div class="mp-list-empty">작성한 댓글이 없습니다.</div>';
            renderPagination('#mp-subpanel-mycomments .pagination', data.currentPage, data.totalPages, loadMyComments);
        });
}

function renderPagination(selector, current, total, loadFn) {
    const el = document.querySelector(selector);
    let html = '';
    for (let i = 1; i <= total; i++) {
        html += `<button class="page-btn ${i === current ? 'active' : ''}" data-page="${i}">${i}</button>`;
    }
    el.innerHTML = html;
    el.querySelectorAll('button').forEach(btn => {
        btn.addEventListener('click', () => loadFn(Number(btn.dataset.page)));
    });
}

function formatDate(arr) {
    if (!Array.isArray(arr)) return arr;
    const [y, m, d, h, min] = arr;
    return `${y}.${String(m).padStart(2,'0')}.${String(d).padStart(2,'0')} ${String(h).padStart(2,'0')}:${String(min).padStart(2,'0')}`;
}

// myposts/mycomments 카테고리 필터칩
document.querySelectorAll('.mp-filter-row[data-scope]').forEach(row => {
  const scope = row.dataset.scope;
  row.querySelectorAll('.mp-filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      row.querySelectorAll('.mp-filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      filterState[scope] = chip.dataset.category;
      if (scope === 'myposts') loadMyPosts(1);
      if (scope === 'mycomments') loadMyComments(1);
      if (scope === 'wronganswer') loadWrongAnswers(1);
      if (scope === 'jamohistory') loadJamoHistory(1);
    });
  });
});

// 필터 칩: 같은 .mp-filter-row 안에서만 active 토글 (탭이 여러 개라 전역으로 묶으면 서로 간섭함)
document.querySelectorAll('.mp-filter-row').forEach(row => {
  row.querySelectorAll('.mp-filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      row.querySelectorAll('.mp-filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
    });
  });
});

loadedTabs.wronganswer = false;
filterState.wronganswer = '';

const waTypeLabel = { CONSONANT: '자음', VOWEL: '모음', WORD: '단어' };

function loadWrongAnswers(page) {
    fetch(`/member/mypage/wronganswer?page=${page}&category=${filterState.wronganswer}`)
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;
            loadedTabs.wronganswer = true;

            document.getElementById('wa-total-badge').textContent = `틀린 단어 ${data.totalCount}개`;

            const tbody = document.getElementById('wrongnote-tbody');
            const startNo = (data.currentPage - 1) * 10;

            tbody.innerHTML = data.wrongAnswers.length ? data.wrongAnswers.map((w, i) => `
                <tr>
                    <td style="color:var(--text-sub); font-size:14px;">${startNo + i + 1}</td>
                    <td style="font-size:17px; font-weight:900;">${w.signWordName}</td>
                    <td><span class="wrong-badge quiz">${waTypeLabel[w.testSessionType] || w.testSessionType}</span></td>
                    <td style="font-size:14px;"><span style="color:var(--danger);">${w.userAnswer || '-'}</span> → <span style="color:var(--primary);">${w.signWordName}</span></td>
                    <td class="mp-hdate">${formatDate(w.answerDate)}</td>
                    <td><a href="/learn/dict?word=${encodeURIComponent(w.signWordName)}" class="retry-tag">다시 학습</a></td>
                </tr>
            `).join('') : '<tr><td colspan="6" class="mp-empty">오답 기록이 없습니다.</td></tr>';

            renderPagination('#mp-panel-wronganswer .pagination', data.currentPage, data.totalPages, loadWrongAnswers);
        });
}

// 화면 설정: 테마 (라이트/다크/시스템)
function applyTheme(value) {
  if (value === 'system') {
    const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
  } else {
    document.documentElement.setAttribute('data-theme', value);
  }
}
const savedTheme = localStorage.getItem('sb-theme') || 'light';
applyTheme(savedTheme);
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
  if ((localStorage.getItem('sb-theme') || 'light') === 'system') applyTheme('system');
});

// 화면 설정: 글자 크기 (작게/보통/크게)
function applyFontSize(value) {
  document.body.classList.remove('fs-small', 'fs-large');
  if (value === 'small') document.body.classList.add('fs-small');
  if (value === 'large') document.body.classList.add('fs-large');
}
const savedFontSize = localStorage.getItem('sb-fontsize') || 'normal';
applyFontSize(savedFontSize);

// 화면 설정 선택 카드 공통 처리 (그룹별로 하나만 selected, 클릭 시 저장 + 즉시 적용)
document.querySelectorAll('.mp-choice-row').forEach(row => {
  const group = row.dataset.group;
  const saved = group === 'theme' ? savedTheme : savedFontSize;
  row.querySelectorAll('.mp-choice').forEach(choice => {
    if (choice.dataset.value === saved) choice.classList.add('selected');
    choice.addEventListener('click', () => {
      row.querySelectorAll('.mp-choice').forEach(c => c.classList.remove('selected'));
      choice.classList.add('selected');
      const value = choice.dataset.value;
      if (group === 'theme') { localStorage.setItem('sb-theme', value); applyTheme(value); }
      if (group === 'fontsize') { localStorage.setItem('sb-fontsize', value); applyFontSize(value); }
    });
  });
});


const basicInfoForm = document.getElementById('basicInfoForm');
basicInfoForm.addEventListener('submit', async function(e) {
  e.preventDefault();

  const csrfToken = document.querySelector('meta[name="_csrf"]').content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

  const body = new URLSearchParams();
  body.set('memberId', document.querySelector('input[name="memberId"]').value);
  body.set('memberName', document.getElementById('name').value);

  const res = await fetch('/member/update', {
    method: 'POST',
    headers: { [csrfHeader]: csrfToken },
    body: body
  });

  const data = await res.json();
  if (data.success) {
    alert('변경 사항이 저장되었습니다.');
  } else {
    alert(data.message || '변경 사항이 저장에 실패했습니다.');
  }
});

const passwordForm = document.getElementById('passwordForm')
if(passwordForm) {
    passwordForm.addEventListener('submit', async function(e) {
    e.preventDefault();

    const currentPw = document.getElementById('pw-current').value;
    const newPw = document.getElementById('pw-new').value;
    const confirmPw = document.getElementById('pw-confirm').value;

    if (!currentPw || !newPw || !confirmPw) {
        alert('모든 항목을 입력해주세요.');
        return;
    }
    if (newPw.length < 8) {
        alert('새 비밀번호는 8자 이상이어야 합니다.');
        return;
    }
    if (newPw !== confirmPw) {
        alert('새 비밀번호가 일치하지 않습니다.');
        return;
    }

    const csrfToken = document.querySelector('meta[name="_csrf"]').content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

    const body = new URLSearchParams();
    body.set('currentPassword', currentPw);
    body.set('newPassword', newPw);

    const res = await fetch('/member/passUpdate', {
        method: 'POST',
        headers: { [csrfHeader]: csrfToken },
        body: body
    });

    const data = await res.json();
    if (data.success) {
        alert('성공적으로 비밀번호가 변경되었습니다.');
        document.getElementById('passwordForm').reset();
    } else {
        alert(data.message || '비밀번호 변경에 실패했습니다.');
    }
    });
}

const deleteBtn = document.getElementById('deleteBtn');
if (deleteBtn) {
  deleteBtn.addEventListener('click', async function() {
    if (!confirm('정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.')) return;

    const csrfToken = document.querySelector('meta[name="_csrf"]').content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

    const body = new URLSearchParams();
    const pwInput = document.getElementById('withdraw-password');
    if (pwInput) body.set('password', pwInput.value);

    const res = await fetch('/member/delete', {
      method: 'POST',
      headers: { [csrfHeader]: csrfToken },
      body: body
    });

    const data = await res.json();
    if (data.success) {
      alert('탈퇴가 완료되었습니다.');
      location.href = '/';
    } else {
      alert(data.message || '탈퇴에 실패했습니다.');
    }
  });
}

loadedTabs.jamohistory = false;
loadedTabs.wordhistory = false;
filterState.jamohistory = '';
filterState.wordhistory = '';

const jamoTypeLabel = { CONSONANT: '자음', VOWEL: '모음' };
const wordTypeLabel = { CONSONANT: '자음', VOWEL: '모음', WORD: '단어' };

function accClass(acc) {
    if (acc >= 0.9) return 'acc-high';
    if (acc >= 0.6) return 'acc-mid';
    return 'acc-low';
}

function loadJamoHistory(page) {
    fetch(`/member/mypage/history/jamo?page=${page}&category=${filterState.jamohistory}`)
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;
            loadedTabs.jamohistory = true;
            const wrap = document.getElementById('jamo-history-wrap');
            wrap.innerHTML = data.jamoHistory.length ? data.jamoHistory.map(h => `
                <div class="history-row">
                    <div class="hcell hcell-word">${h.jamoChar}<div class="meta">${jamoTypeLabel[h.jamoType] || h.jamoType}</div></div>
                    <div class="hcell hcell-date">${formatDate(h.regDate)}</div>
                    <div class="hcell"><span class="acc-chip ${accClass(h.confidence)}">${Math.round(h.confidence * 100)}%</span></div>
                </div>
            `).join('') : '<div class="mp-list-empty">학습 기록이 없습니다.</div>';
            renderPagination('#mp-subpanel-jamo .pagination', data.currentPage, data.totalPages, loadJamoHistory);
        });
}

function loadWordHistory(page) {
    fetch(`/member/mypage/history/word?page=${page}`)
        .then(res => res.json())
        .then(data => {
            if (!data.success) return;
            loadedTabs.wordhistory = true;
            const wrap = document.getElementById('word-history-wrap');
            wrap.innerHTML = data.wordHistory.length ? data.wordHistory.map(h => `
                <div class="history-row">
                    <div class="hcell hcell-word">${h.signWordName}</div>
                    <div class="hcell hcell-date">${formatDate(h.answerDate)}</div>
                    <div class="hcell"><span class="acc-chip ${h.isCorrect === 'Y' ? 'acc-high' : 'acc-low'}">${h.isCorrect === 'Y' ? '정답' : '오답'}</span></div>
                </div>
            `).join('') : '<div class="mp-list-empty">학습 기록이 없습니다.</div>';
            renderPagination('#mp-subpanel-word .pagination', data.currentPage, data.totalPages, loadWordHistory);
        });
}
