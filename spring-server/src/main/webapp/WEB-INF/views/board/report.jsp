<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 오류 신고</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">
    <div class="edit-wrap">

      <div class="edit-header">
        <h1>⚠️ 오류 신고</h1>
        <p>수어 인식, 영상 재생, 번역 등에서 발견한 문제를 알려주세요. 확인 후 빠르게 수정하겠습니다.</p>
      </div>

      <div class="card">
        <form id="reportForm" action="/board/write" method="post">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
          <!-- 이 폼은 항상 REPORT 카테고리로 고정 -->
          <input type="hidden" name="categoryIdx" value="REPORT">

          <div class="form-group">
            <label class="form-label" for="report-category">오류 유형</label>
            <select id="report-category" class="form-input">
              <option>동작 인식 오류</option>
              <option>영상 재생 오류</option>
              <option>번역 · 뜻풀이 오류</option>
              <option>화면 · 디자인 오류</option>
              <option>기타</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label" for="report-word">관련 단어 / 기능</label>
            <input type="text" id="report-word" class="form-input" placeholder="예: 감사합니다, 자음 지문자 학습 등">
            <div class="form-hint">문제가 발생한 학습 페이지나 단어를 적어주시면 확인이 빨라져요.</div>
          </div>

          <div class="form-group">
            <label class="form-label" for="title">제목</label>
            <input type="text" class="form-input" id="title" name="boardTitle" maxlength="80" placeholder="오류 내용을 한 줄로 요약해주세요" required>
          </div>

          <div class="form-group">
            <label class="form-label" for="boardContent">상세 내용</label>
            <textarea class="form-input" id="boardContent" name="boardContent" rows="10" maxlength="2000" placeholder="어떤 상황에서 문제가 발생했는지, 재현 방법을 자세히 적어주세요." required></textarea>
            <div class="form-hint">브라우저, 기기(OS) 정보를 함께 적어주시면 원인 파악에 도움이 됩니다.</div>
            <div class="char-count"><span id="charCount">0</span> / 2000</div>
          </div>

          <div class="alert alert-warn">신고 처리 상황은 별도로 알려드리지 않고, 확인이 필요한 경우 이 글의 댓글로 안내드립니다.</div>

          <div class="edit-actions">
            <a href="/board/list" class="btn btn-ghost">취소</a>
            <button type="submit" class="btn btn-primary">신고 등록</button>
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

// 오류 유형 + 관련 단어를 제목 앞에 자동으로 붙여서 같이 전송
// (서버 BoardVO에 별도 컬럼이 없어서 제목에 태그처럼 합침)
document.getElementById('reportForm').addEventListener('submit', function () {
  const category = document.getElementById('report-category').value;
  const word = document.getElementById('report-word').value.trim();
  const titleEl = document.getElementById('title');

  let prefix = '[' + category + ']';
  if (word) prefix += ' (' + word + ')';


  titleEl.value = prefix + ' ' + titleEl.value;
});
</script>

</body>
</html>