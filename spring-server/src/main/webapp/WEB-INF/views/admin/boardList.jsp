<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="pageTitle" value="게시글 목록" scope="request" />
<c:set var="pageName" value="board" scope="request" />
<c:set var="activeMenu" value="board-list" scope="request" />
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - ${pageTitle}</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/resources/css/admin.css">
</head>
<body>

<jsp:include page="includes/header.jsp" />

<div class="page-header">
  <div>
    <div class="section-eyebrow">게시판 관리</div>
    <div class="section-hd">게시글 목록</div>
  </div>
</div>

<div class="tabs">
  <a href="?category=" class="tab ${empty param.category ? 'active' : ''}">전체</a>
  <a href="?category=NOTICE" class="tab ${param.category == 'NOTICE' ? 'active' : ''}">공지</a>
  <a href="?category=FREE" class="tab ${param.category == 'FREE' ? 'active' : ''}">자유</a>
  <a href="?category=INFO" class="tab ${param.category == 'INFO' ? 'active' : ''}">정보</a>
  <a href="?category=QNA" class="tab ${param.category == 'QNA' ? 'active' : ''}">질문</a>
  <a href="?category=REPORT" class="tab ${param.category == 'REPORT' ? 'active' : ''}">신고</a>
</div>

<form class="filter-bar" method="get" action="${pageContext.request.contextPath}/admin/board/list">
  <input type="hidden" name="category" value="${param.category}">
  <div class="search-wrap">
    <span class="si">🔍</span>
    <input type="text" name="keyword" value="${param.keyword}" placeholder="제목, 작성자, 내용 검색...">
  </div>
  <select class="filter-select" name="sort" onchange="this.form.submit()">
    <option value="newest" ${param.sort == 'newest' || empty param.sort ? 'selected' : ''}>최신순</option>
    <option value="oldest" ${param.sort == 'oldest' ? 'selected' : ''}>오래된순</option>
    <option value="views" ${param.sort == 'views' ? 'selected' : ''}>조회수순</option>
  </select>
</form>

<div class="table-wrap">
  <table>
    <thead>
      <tr><th>#</th><th>카테고리</th><th>제목</th><th>작성자</th><th>작성일</th><th>조회</th><th>작업</th></tr>
    </thead>
    <tbody>
      <c:forEach var="board" items="${boardList}">
        <tr>
          <td class="td-mono">#${board.boardId}</td>
          <td>
            <c:choose>
              <c:when test="${board.categoryIdx == 'NOTICE'}"><span class="pill notice">공지</span></c:when>
              <c:when test="${board.categoryIdx == 'FREE'}"><span class="pill free">자유</span></c:when>
              <c:when test="${board.categoryIdx == 'INFO'}"><span class="pill info">정보</span></c:when>
              <c:when test="${board.categoryIdx == 'QNA'}"><span class="pill qna">질문</span></c:when>
              <c:when test="${board.categoryIdx == 'REPORT'}"><span class="pill report">신고</span></c:when>
              <c:otherwise><span class="pill">${board.categoryIdx}</span></c:otherwise>
            </c:choose>
          </td>
          <td>${board.boardTitle}</td>
          <td>${board.memberName}</td>
          <td class="td-mono">${fn:substring(board.regDate, 0, 10)}</td>
          <td class="td-mono">${board.viewCount}</td>
          <td>
            <button type="button" class="topbar-btn btn-danger" style="padding:4px 10px;font-size:12px"
                    onclick="openModal('modal-board-delete');document.getElementById('board-delete-id').value='${board.boardId}'">삭제</button>
          </td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
</div>

<div class="pagination">
  <a class="pg-btn" href="${pageContext.request.contextPath}/admin/board/list?page=${pageBean.prevPage}&category=${param.category}">‹</a>
  <c:forEach var="p" begin="${pageBean.min}" end="${pageBean.max}">
    <a class="pg-btn ${p == pageBean.currentPage ? 'active' : ''}" href="${pageContext.request.contextPath}/admin/board/list?page=${p}&category=${param.category}">${p}</a>
  </c:forEach>
  <a class="pg-btn" href="${pageContext.request.contextPath}/admin/board/list?page=${pageBean.nextPage}&category=${param.category}">›</a>
</div>

<!-- 게시글 삭제 모달 -->
<div class="modal-overlay" id="modal-board-delete">
  <div class="modal">
    <form method="post" action="${pageContext.request.contextPath}/admin/board/delete">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
      <input type="hidden" name="boardId" id="board-delete-id">
      <div class="modal-title">🗑 게시글 삭제</div>
      <div class="modal-desc">이 게시글을 삭제하시겠습니까? 삭제된 게시글은 복구할 수 없습니다.</div>
      <div class="modal-actions">
        <button type="button" class="topbar-btn btn-ghost" onclick="closeModal('modal-board-delete')">취소</button>
        <button type="submit" class="topbar-btn btn-danger">삭제</button>
      </div>
    </form>
  </div>
</div>

<jsp:include page="includes/footer.jsp" />
<script>
function openModal(id) {
  document.getElementById(id).classList.add('open');
}
function closeModal(id) {
  document.getElementById(id).classList.remove('open');
}
</script>
</body>
</html>