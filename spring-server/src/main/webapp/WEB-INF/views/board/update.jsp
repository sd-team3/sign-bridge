<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 게시글 수정</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">
    <div class="edit-wrap">

      <div class="edit-header">
        <h1>게시글 수정</h1>
        <p>수정 후 저장하면 수정일자가 갱신돼요!</p>
      </div>

      <div class="alert alert-warn">작성하신 원문은 저장되지 않으니, 수정 전 내용을 미리 확인해주세요.</div>

      <div class="card">
        <form id="editForm" action="/board/update" method="post">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
          <input type="hidden" name="boardId" value="${board.boardId}">
          <div class="form-group">
            <label class="form-label" for="category">카테고리</label>
            <select class="form-input" id="category" name="categoryIdx">
              <option value="QNA" ${board.categoryIdx == 'QNA' ? 'selected' : ''}>질문</option>
              <option value="FREE" ${board.categoryIdx == 'FREE' ? 'selected' : ''}>자유</option>
              <option value="INFO" ${board.categoryIdx == 'INFO' ? 'selected' : ''}>정보</option>
              <option value="REPORT" ${board.categoryIdx == 'REPORT' ? 'selected' : ''}>오류 신고</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label" for="title">제목</label>
            <input type="text" class="form-input" id="title" name="boardTitle" maxlength="80" value="${board.boardTitle}">
          </div>

          <div class="form-group">
            <label class="form-label" for="content">내용</label>
            <textarea class="form-input" id="boardContent" name="boardContent" rows="10" maxlength="2000">${board.boardContent}</textarea>
            <div class="form-hint">최소 10자 이상 작성해주세요.</div>
            <div class="char-count"><span id="charCount">0</span> / 2000</div>
          </div>

          <div class="edit-actions">
            <a href="/board/list?category=${board.categoryIdx}" class="btn btn-ghost">취소</a>
            <button type="submit" class="btn btn-primary">수정 완료</button>
          </div>
        </form>
      </div>

    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script>
const contentEl = document.getElementById('boardContent');
const charCountEl = document.getElementById('charCount');
function updateCount(){ charCountEl.textContent = contentEl.value.length; }
contentEl.addEventListener('input', updateCount);
updateCount();

</script>

</body>
</html>
