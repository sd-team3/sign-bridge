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
          <button class="filter-tab active">전체</button>
          <button class="filter-tab">질문</button>
          <button class="filter-tab">정보</button>
          <button class="filter-tab">⚠️ 오류신고</button>
          <button class="filter-tab">➕ 단어건의</button>
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
                <div class="post-item" onclick="location.href='board_detail.html'">
                  <div class="post-badge-col"><span class="badge badge-primary">${board.categoryIdx}</span></div>
                  <div class="post-main">
                    <div class="post-title">${board.boardTitle}</div>
                    <div class="post-meta"><span>${board.memberName}</span><span>댓글 3</span></div>
                  </div>
                  <div class="post-right"><div class="post-date">${board.regDate}</div><div class="post-views">조회 ${board.viewCount}</div></div>
                </div>
              </c:forEach>
            </c:otherwise>

          </c:choose>
        </div>

        <div class="pagination">
          <button class="page-btn active">1</button>
          <button class="page-btn">2</button>
          <button class="page-btn">3</button>
          <button class="page-btn">→</button>
        </div>
      </div>

      <!-- 사이드바 -->
      <div class="board-sidebar">
        <div class="sidebar-box">
          <div class="sidebar-box-header">글쓰기</div>
          <div class="sidebar-write-btns">
            <a href="/board/write" class="btn btn-primary btn-sm">✏️ 일반 글쓰기</a>
            <a href="board_report.html" class="btn btn-ghost btn-sm">⚠️ 오류 신고</a>
            <a href="board_suggest.html" class="btn btn-ghost btn-sm">➕ 단어 건의</a>
          </div>
        </div>
        <div class="sidebar-box">
          <div class="sidebar-box-header">게시판 현황</div>
          <div class="sidebar-stats">
            <div class="stat-row"><span class="lbl">전체 게시글</span><span class="val">247</span></div>
            <div class="stat-row"><span class="lbl">오류 신고</span><span class="val">18</span></div>
            <div class="stat-row"><span class="lbl">단어 건의</span><span class="val">43</span></div>
            <div class="stat-row"><span class="lbl">해결된 이슈</span><span class="val">31</span></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />
</body>
</html>