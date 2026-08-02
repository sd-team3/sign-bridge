(function () {
  const boardId = document.querySelector('.comment-section').dataset.boardId;
  const csrfToken = document.querySelector('meta[name="_csrf"]').content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

  const listEl = document.querySelector('.comment-list');
  const countEl = document.querySelector('.comment-count-title span');
  const writeArea = document.querySelector('.comment-write');
  const writeTextarea = writeArea.querySelector('textarea');
  const writeBtn = writeArea.querySelector('.btn-primary');

  let currentMemberId = null;
  let isLoggedIn = false;

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str || '';
    return div.innerHTML;
  }

  function avatarChar(name) {
    return (name || '?').charAt(0);
  }

  async function apiFetch(url, options) {
    options = options || {};
    options.headers = Object.assign({}, options.headers, { [csrfHeader]: csrfToken });
    const res = await fetch(url, options);
    const contentType = res.headers.get('content-type') || '';
    if (!contentType.includes('application/json')) {
      // 세션 만료 등으로 로그인 페이지 HTML이 대신 온 경우
      alert('로그인이 필요합니다. 다시 로그인해주세요.');
      location.href = '/member/login';
      throw new Error('Not JSON response — likely redirected to login');
    }
    return res.json();
  }

  function buildReplyHtml(reply) {
    const isDeleted = comment.delYn === 'Y';
    const canDelete = !isDeleted && isLoggedIn && currentMemberId === reply.memberId;
    const content = isDeleted ? '삭제된 댓글입니다.' : escapeHtml(reply.commentContent);
    return `
      <div class="comment-reply" data-comment-id="${reply.commentId}">
        <div class="comment-item-header">
          <div class="comment-avatar">${escapeHtml(avatarChar(reply.memberName))}</div>
          <span class="comment-author">${escapeHtml(reply.memberName)}</span>
          <span class="comment-time">${escapeHtml(reply.formattedRegDate)}</span>
        </div>
        <div class="comment-body${isDeleted ? ' comment-deleted' : ''}">${content}</div>
        ${canDelete ? `
        <div class="comment-actions">
          <button class="comment-reply-btn" data-action="delete" data-comment-id="${reply.commentId}">삭제</button>
        </div>` : ''}
      </div>
    `;
  }

  function buildCommentHtml(comment, replies) {
    const isDeleted = comment.delYn === 'Y';
    const canDelete = !isDeleted && isLoggedIn && currentMemberId === comment.memberId;
    const content = isDeleted ? '삭제된 댓글입니다.' : escapeHtml(comment.commentContent);
    const replyFormId = `reply-form-${comment.commentId}`;
    const repliesHtml = replies.map(buildReplyHtml).join('');

    return `
      <div class="comment-item" data-comment-id="${comment.commentId}">
        <div class="comment-item-header">
          <div class="comment-avatar">${escapeHtml(avatarChar(comment.memberName))}</div>
          <span class="comment-author">${escapeHtml(comment.memberName)}</span>
          <span class="comment-time">${escapeHtml(comment.formattedRegDate)}</span>
        </div>
        <div class="comment-body${isDeleted ? ' comment-deleted' : ''}">${content}</div>
        <div class="comment-actions">
          ${!isDeleted && isLoggedIn ? `<button class="comment-reply-btn" data-action="toggle-reply" data-target="${replyFormId}">답글</button>` : ''}
          ${canDelete ? `<button class="comment-reply-btn" data-action="delete" data-comment-id="${comment.commentId}">삭제</button>` : ''}
        </div>
        <div class="comment-reply-form" id="${replyFormId}">
          <textarea placeholder="답글을 입력하세요..."></textarea>
          <div class="comment-reply-form-footer">
            <button class="btn btn-ghost btn-sm" data-action="toggle-reply" data-target="${replyFormId}">취소</button>
            <button class="btn btn-primary btn-sm" data-action="submit-reply" data-parent="${comment.commentId}">답글 등록</button>
          </div>
        </div>
        ${repliesHtml ? `<div class="comment-replies">${repliesHtml}</div>` : ''}
      </div>
    `;
  }

  function renderWriteArea() {
    if (isLoggedIn) return; // 기본 마크업(작성창) 그대로 둠
    writeArea.innerHTML = '<p class="comment-login-prompt">댓글을 작성하려면 <a href="/member/login">로그인</a>이 필요합니다.</p>';
  }

  function render(comments) {
    const topLevel = comments.filter(c => c.parentCommentId == null);
    const repliesByParent = {};
    comments.filter(c => c.parentCommentId != null).forEach(c => {
      if (!repliesByParent[c.parentCommentId]) repliesByParent[c.parentCommentId] = [];
      repliesByParent[c.parentCommentId].push(c);
    });

    if (topLevel.length === 0) {
      listEl.innerHTML = '<div class="comment-empty">아직 작성된 댓글이 없습니다. 첫 댓글을 남겨보세요!</div>';
    } else {
      listEl.innerHTML = topLevel
        .map(c => buildCommentHtml(c, repliesByParent[c.commentId] || []))
        .join('');
    }

    countEl.textContent = comments.length;
    const statNumEl = document.getElementById('commentStatNum');
    if (statNumEl) statNumEl.textContent = comments.length;
  }

  async function loadComments() {
    const data = await apiFetch(`/comment/list?boardId=${boardId}`);
    currentMemberId = data.currentMemberId;
    isLoggedIn = data.isLoggedIn;
    renderWriteArea();
    render(data.comments || []);
  }

  async function submitComment(content, parentCommentId) {
    if (!content || !content.trim()) {
      alert('내용을 입력해주세요.');
      return false;
    }
    const body = new URLSearchParams();
    body.set('boardId', boardId);
    body.set('commentContent', content);
    if (parentCommentId) body.set('parentCommentId', parentCommentId);

    const data = await apiFetch('/comment/write', { method: 'POST', body });
    if (!data.success) {
      alert(data.message || '등록에 실패했습니다.');
      return false;
    }
    return true;
  }

  async function deleteComment(commentId) {
    if (!confirm('댓글을 삭제하시겠습니까?')) return;
    const body = new URLSearchParams();
    body.set('commentId', commentId);
    body.set('boardId', boardId);

    const data = await apiFetch('/comment/delete', { method: 'POST', body });
    if (!data.success) {
      alert(data.message || '삭제에 실패했습니다.');
      return;
    }
    await loadComments();
  }

  // 최상위 댓글 작성 (로그인 상태일 때만 이 버튼이 남아있음)
  writeArea.addEventListener('click', async (e) => {
    if (!e.target.classList.contains('btn-primary')) return;
    const textarea = writeArea.querySelector('textarea');
    if (!textarea) return;
    const ok = await submitComment(textarea.value, null);
    if (ok) {
      textarea.value = '';
      await loadComments();
    }
  });

  // 이벤트 위임: 답글 토글 / 답글 등록 / 삭제
  listEl.addEventListener('click', async (e) => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const action = btn.dataset.action;

    if (action === 'toggle-reply') {
      document.getElementById(btn.dataset.target).classList.toggle('open');
    } else if (action === 'submit-reply') {
      const form = btn.closest('.comment-reply-form');
      const textarea = form.querySelector('textarea');
      const ok = await submitComment(textarea.value, btn.dataset.parent);
      if (ok) {
        textarea.value = '';
        await loadComments();
      }
    } else if (action === 'delete') {
      await deleteComment(btn.dataset.commentId);
    }
  });

  loadComments();
})();