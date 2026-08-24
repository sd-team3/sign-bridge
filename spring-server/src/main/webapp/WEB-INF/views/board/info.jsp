<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="_csrf" content="${_csrf.token}">
<meta name="_csrf_header" content="${_csrf.headerName}">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - 게시글 상세</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="detail-layout">
      <!-- 메인 -->
      <div>
      <!-- 오류 신고 부분 -->
      <c:if test="${board.categoryIdx == 'REPORT'}">
        <div class="report-detail-box">
          <div class="report-detail-row">
            <span>오류 유형</span>
            <span>
              <c:choose>
                <c:when test="${errorType == 'ACTION_RECOGNITION'}">동작 인식 오류</c:when>
                <c:when test="${errorType == 'VIDEO_PLAYBACK'}">영상 재생 오류</c:when>
                <c:when test="${errorType == 'TRANSLATION'}">번역 · 뜻풀이 오류</c:when>
                <c:when test="${errorType == 'UI_BUG'}">화면 · 디자인 오류</c:when>
                <c:when test="${errorType == 'ETC'}">기타</c:when>
                <c:otherwise>${errorType}</c:otherwise>
              </c:choose>
            </span>
          </div>
        </div>
      </c:if>
        <!-- 게시글 헤더 -->
        <div class="detail-header">
          <div class="detail-badge-row">
            <c:choose>
              <c:when test="${board.categoryIdx == 'FREE'}"><span class="badge badge-primary">자유</span></c:when>
              <c:when test="${board.categoryIdx == 'INFO'}"><span class="badge badge-primary">정보</span></c:when>
              <c:when test="${board.categoryIdx == 'QNA'}"><span class="badge badge-primary">질문</span></c:when>
              <c:when test="${board.categoryIdx == 'NOTICE'}"><span class="badge badge-warn">공지</span></c:when>
              <c:when test="${board.categoryIdx == 'REPORT'}"><span class="badge badge-danger">신고</span></c:when>
              <c:otherwise><span class="badge badge-danger">알수없음</span></c:otherwise>
            </c:choose>
          </div>
          <div class="detail-title">${board.boardTitle}</div>
          <div class="detail-meta">
            <div class="detail-author">
              <!-- 이름 첫번째 글자만 -->
              <div class="author-avatar">${fn:substring(board.memberName, 0, 1)}</div>
              <div>
                <div class="author-name">${board.memberName}</div>
                <div class="author-date">게시일: ${board.formattedRegDate}</div>
                <c:if test="${not empty board.formattedModDate}">
                  <div class="author-date">수정일: ${board.formattedModDate}</div>
                </c:if>
              </div>
            </div>
            <div class="detail-stats">
              <span>조회 ${board.viewCount}</span>
              <span>댓글 <span id="commentStatNum">0</span></span>
            </div>
          </div>
        </div>

        <!-- 게시글 본문 -->
        <div class="detail-content">
          ${board.boardContent}
          <c:if test="${not empty boardFiles}">
            <div class="detail-images">
              <c:forEach var="f" items="${boardFiles}">
                <c:choose>
                  <c:when test="${f.fileType == 'IMAGE'}">
                    <img src="${f.filePath}" alt="${f.origName}" onclick="window.open(this.src)">
                  </c:when>
                  <c:otherwise>
                    <video src="${f.filePath}" controls></video>
                  </c:otherwise>
                </c:choose>
              </c:forEach>
            </div>
          </c:if>
        </div>

        <c:if test="${not empty currentMemberId and currentMemberId == board.memberId}">
          <div class="detail-actions">
            <a href="/board/update?boardId=${board.boardId}" class="btn btn-ghost btn-sm">수정</a>
            <button class="btn btn-ghost btn-sm" onclick="openDeleteModal()">삭제</button>
          </div>
        </c:if>

        <!-- 댓글 섹션 -->
        <div class="comment-section" data-board-id="${board.boardId}">
          <div class="comment-count-title">댓글 <span>0</span></div>

          <div class="comment-write">
            <textarea placeholder="댓글을 입력하세요..."></textarea>
            <div class="comment-write-footer">
              <button class="btn btn-primary btn-sm">댓글 등록</button>
            </div>
          </div>

          <div class="comment-list"></div>
        </div>

        <div class="back-row">
          <a href="/board/list?category=${board.categoryIdx}" class="btn btn-ghost btn-sm">← 목록으로</a>
        </div>

      </div>
      <jsp:include page="./includes/sidebar.jsp" />
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<!-- 게시글 삭제 확인 모달 -->
<div class="modal-backdrop" id="deleteModal">
  <div class="modal">
    <div class="modal-header">
      <span class="modal-title">게시글을 삭제할까요?</span>
      <button class="modal-close" onclick="closeDeleteModal()">✕</button>
    </div>
    <div class="modal-body">
      <div class="modal-content">삭제한 게시글과 댓글 <span>0</span>개는 복구할 수 없습니다. 정말 삭제하시겠어요?</div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-ghost btn-sm" onclick="closeDeleteModal()">취소</button>
      <form id="deleteForm" action="/board/delete" method="post">
        <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
        <input type="hidden" name="boardId" value="${board.boardId}">
        <button type="submit" class="btn btn-danger btn-sm">삭제하기</button>
      </form>
    </div>
  </div>
</div>

<script>
function openDeleteModal() {
  document.getElementById('deleteModal').classList.add('open');
}
function closeDeleteModal() {
  document.getElementById('deleteModal').classList.remove('open');
}
function toggleReplyForm(btn, id) {
  document.getElementById(id).classList.toggle('open');
}
</script>
<script src="/resources/js/comment.js"></script>
</body>
</html>
