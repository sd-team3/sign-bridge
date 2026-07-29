<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 게시판</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">
    <div class="board-top">
      <div>
        <h1>💬 게시판</h1>
        <p style="font-size:13px; color:var(--text-muted); margin-top:4px;">질문, 답변, 수어 단어 오류 신고, 추가 건의를 자유롭게 올려주세요.</p>
      </div>
    </div>

    <div class="board-layout">
      <!-- 메인 -->
      <div>
        <div class="search-row">
          <input type="text" class="search-field" placeholder="게시글 검색...">
          <button class="btn btn-primary btn-sm">검색</button>
        </div>

        <div class="filter-tabs">
          <a href="/board/list" class="filter-tab ${category == '' || category == null ? 'active' : '' }">전체</a>
          <a href="/board/list?category=NOTICE" class="filter-tab ${category == 'NOTICE' ? 'active' : '' }">공지</a>
          <a href="/board/list?category=FREE" class="filter-tab ${category == 'FREE' ? 'active' : '' }">자유</a>
          <a href="/board/list?category=QNA" class="filter-tab ${category == 'QNA' ? 'active' : '' }">질문</a>
          <a href="/board/list?category=INFO" class="filter-tab ${category == 'INFO' ? 'active' : '' }">정보</a>
          <a href="/board/list?category=REPORT" class="filter-tab ${category == 'REPORT' ? 'active' : '' }">오류신고</a>
        </div>

        <div class="post-list">
          <c:choose>
            <c:when test="${empty boards}">
              <div class="board-empty">
                <div class="board-empty-icon">💬</div>
                <p class="board-empty-title">등록된 게시글이 없습니다</p>
                <p class="board-empty-desc">첫 번째 글을 작성해보세요!</p>
              </div>
            </c:when>
            <c:otherwise>
              <c:forEach var="board" items="${boards}">
                <a href="/board/info?boardId=${board.boardId}" class="post-item">
                  <div class="post-badge-col">
                    <c:choose>
                      <c:when test="${board.categoryIdx == 'FREE'}"><span class="badge badge-primary">자유</span></c:when>
                      <c:when test="${board.categoryIdx == 'INFO'}"><span class="badge badge-primary">정보</span></c:when>
                      <c:when test="${board.categoryIdx == 'QNA'}"><span class="badge badge-primary">질문</span></c:when>
                      <c:when test="${board.categoryIdx == 'NOTICE'}"><span class="badge badge-warn">공지</span></c:when>
                      <c:when test="${board.categoryIdx == 'REPORT'}"><span class="badge badge-danger">신고</span></c:when>
                      <c:otherwise><span class="badge badge-danger">알수없음</span></c:otherwise>
                    </c:choose>
                  </div>
                  <div class="post-main">
                    <div class="post-title">${board.boardTitle}</div>
                    <div class="post-meta"><span>${board.memberName}</span><span>댓글 3</span></div>
                  </div>
                  <div class="post-right">
                    <div class="post-date">${board.formattedRegDate}</div>
                    <div class="post-views">조회 ${board.viewCount}</div>
                  </div>
                </a>
              </c:forEach>
            </c:otherwise>

          </c:choose>
        </div>

        <div class="pagination">
          <c:choose>
            <c:when test="${pageBean.currentPage <= 1}">
              <span class="page-btn disabled">←</span>
            </c:when>
            <c:otherwise>
              <a href="/board/list?category=${category}&page=${pageBean.prevPage}" class="page-btn">←</a>
            </c:otherwise>
          </c:choose>

          <c:forEach begin="${pageBean.min}" end="${pageBean.max}" var="pageNum">
            <a href="/board/list?category=${category}&page=${pageNum}" class="page-btn ${pageNum == pageBean.currentPage ? 'active' : ''}">${pageNum}</a>
          </c:forEach>

          <c:choose>
            <c:when test="${pageBean.currentPage >= pageBean.totalPageCnt}">
              <span class="page-btn disabled">→</span>
            </c:when>
            <c:otherwise>
              <a href="/board/list?category=${category}&page=${pageBean.nextPage}" class="page-btn">→</a>
            </c:otherwise>
          </c:choose>

        </div>
      </div>
      <jsp:include page="sidebar.jsp" />
    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />
</body>
</html>