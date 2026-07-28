<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="게시글 목록" scope="request" />
<c:set var="pagePath" value="/admin/board/list" scope="request" />
<c:set var="activeMenu" value="board-list" scope="request" />
<jsp:include page="common/header.jsp" />

<div class="page-header">
  <div>
    <div class="section-eyebrow">게시판 관리</div>
    <div class="section-hd">게시글 목록</div>
    <div class="section-sub">카테고리 파라미터로 필터링 가능 <span class="topbar-path" style="font-size:11px">/admin/board/list?category=</span></div>
  </div>
</div>

<div class="tabs">
  <a href="?category=" class="tab ${empty param.category ? 'active' : ''}">전체</a>
  <a href="?category=normal" class="tab ${param.category == 'normal' ? 'active' : ''}">일반</a>
  <a href="?category=question" class="tab ${param.category == 'question' ? 'active' : ''}">질문</a>
  <a href="?category=notice" class="tab ${param.category == 'notice' ? 'active' : ''}">공지</a>
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
      <c:forEach var="post" items="${boardList}">
        <tr>
          <td class="td-mono">#${post.id}</td>
          <td><span class="pill ${post.categoryPillClass}">${post.categoryLabel}</span></td>
          <td>${post.title}</td>
          <td>${post.author}</td>
          <td class="td-mono">${post.createdDate}</td>
          <td class="td-mono">${post.views}</td>
          <td>
            <button type="button" class="topbar-btn btn-danger" style="padding:4px 10px;font-size:12px"
                    onclick="openModal('modal-board-delete');document.getElementById('board-delete-id').value='${post.id}'">삭제</button>
          </td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
</div>

<div class="pagination">
  <a class="pg-btn" href="?page=${pagination.prevPage}&category=${param.category}">‹</a>
  <c:forEach var="p" begin="1" end="${pagination.totalPages}">
    <a class="pg-btn ${p == pagination.currentPage ? 'active' : ''}" href="?page=${p}&category=${param.category}">${p}</a>
  </c:forEach>
  <a class="pg-btn" href="?page=${pagination.nextPage}&category=${param.category}">›</a>
</div>

<!-- 게시글 삭제 모달 -->
<div class="modal-overlay" id="modal-board-delete">
  <div class="modal">
    <form method="post" action="${pageContext.request.contextPath}/admin/board/delete">
      <input type="hidden" name="postId" id="board-delete-id">
      <div class="modal-title">🗑 게시글 삭제</div>
      <div class="modal-desc">이 게시글을 삭제하시겠습니까? 삭제된 게시글은 복구할 수 없습니다.</div>
      <div class="modal-actions">
        <button type="button" class="topbar-btn btn-ghost" onclick="closeModal('modal-board-delete')">취소</button>
        <button type="submit" class="topbar-btn btn-danger">삭제</button>
      </div>
    </form>
  </div>
</div>

<jsp:include page="common/footer.jsp" />
