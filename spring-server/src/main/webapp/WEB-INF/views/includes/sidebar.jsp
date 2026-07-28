<!-- ═══════════ SIDEBAR ═══════════ -->
<aside class="sidebar" id="sidebar">
  <div class="sidebar-logo">
    <div class="sidebar-logo-icon">✋</div>
    <span class="sidebar-logo-text">SignBridge</span>
    <span class="sidebar-logo-badge">ADMIN</span>
  </div>

  <nav class="sidebar-nav">
    <div class="nav-group">
      <div class="nav-group-label">개요</div>
      <a class="nav-item active" data-page="dashboard" data-path="/admin" onclick="navigate(this)">
        <span class="ni">📊</span> 대시보드
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">사용자</div>
      <a class="nav-item" data-page="user-list" data-path="/admin/user/list" onclick="navigate(this)">
        <span class="ni">👥</span> 유저 목록
      </a>
      <a class="nav-item" data-page="user-info" data-path="/admin/user/info" onclick="navigate(this)">
        <span class="ni">👤</span> 유저 상세
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">단어 관리</div>
      <a class="nav-item" data-page="word-add" data-path="/admin/word/add" onclick="navigate(this)">
        <span class="ni">➕</span> 단어 추가
      </a>
      <a class="nav-item" data-page="word-update" data-path="/admin/word/update" onclick="navigate(this)">
        <span class="ni">✏️</span> 단어 수정
      </a>
      <a class="nav-item" data-page="word-delete" data-path="/admin/word/delete" onclick="navigate(this)">
        <span class="ni">🗑️</span> 단어 삭제
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">게시판</div>
      <a class="nav-item" data-page="board-list" data-path="/admin/board/list" onclick="navigate(this)">
        <span class="ni">💬</span> 게시글 목록
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">문의 / 신고</div>
      <a class="nav-item" data-page="question-error" data-path="/admin/question/error" onclick="navigate(this)">
        <span class="ni">🚨</span> 오류 신고
        <span class="badge">4</span>
      </a>
      <a class="nav-item" data-page="question-add" data-path="/admin/question/add" onclick="navigate(this)">
        <span class="ni">📝</span> 단어 관리
        <span class="badge">9</span>
      </a>
    </div>
  </nav>

  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="sidebar-avatar">관</div>
      <div class="sidebar-user-info">
        <div class="sidebar-user-name">관리자</div>
        <div class="sidebar-user-role">Super Admin</div>
      </div>
      <div class="sidebar-logout" title="로그아웃" onclick="showToast('로그아웃 되었습니다', '#c0392b')">⏻</div>
    </div>
  </div>
</aside>