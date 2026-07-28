<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

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
      <a class="nav-item ${activeMenu == 'dashboard' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin">
        <span class="ni">📊</span> 대시보드
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">사용자</div>
      <a class="nav-item ${activeMenu == 'user-list' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/user/list">
        <span class="ni">👥</span> 유저 목록
      </a>
      <a class="nav-item ${activeMenu == 'user-info' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/user/info">
        <span class="ni">👤</span> 유저 상세
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">단어 관리</div>
      <a class="nav-item ${activeMenu == 'word-add' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/word/add">
        <span class="ni">➕</span> 단어 추가
      </a>
      <a class="nav-item ${activeMenu == 'word-update' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/word/update">
        <span class="ni">✏️</span> 단어 수정
      </a>
      <a class="nav-item ${activeMenu == 'word-delete' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/word/delete">
        <span class="ni">🗑️</span> 단어 삭제
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">게시판</div>
      <a class="nav-item ${activeMenu == 'board-list' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/board/list">
        <span class="ni">💬</span> 게시글 목록
      </a>
    </div>

    <div class="nav-group">
      <div class="nav-group-label">문의 / 신고</div>
      <a class="nav-item ${activeMenu == 'question-error' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/question/error">
        <span class="ni">🚨</span> 오류 신고
        <c:if test="${not empty pendingErrorCount && pendingErrorCount > 0}">
          <span class="badge">${pendingErrorCount}</span>
        </c:if>
      </a>
      <a class="nav-item ${activeMenu == 'question-add' ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/question/add">
        <span class="ni">📝</span> 단어 요청
        <c:if test="${not empty pendingRequestCount && pendingRequestCount > 0}">
          <span class="badge">${pendingRequestCount}</span>
        </c:if>
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
