<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 게시글 작성</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">
    <div class="edit-wrap">

      <div class="edit-header">
        <h1>게시글 작성</h1>
        <p>질문, 자유, 오류 신고, 단어 건의 등 카테고리에 맞게 작성해주세요.</p>
        <p style="color:red;">DEBUG isAdmin = [${isAdmin}]</p>
      </div>

      <div class="card">
        <form id="writeForm" action="/board/write" method="post">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
          <div class="form-group">
            <label class="form-label" for="category">카테고리</label>
            <select class="form-input" id="category" name="categoryIdx" required>
              <option value="" disabled selected>카테고리를 선택하세요</option>
              <c:if test="${isAdmin}">
                <option value="NOTICE">공지</option>
              </c:if>
              <option value="QNA">질문</option>
              <option value="FREE">자유</option>
              <option value="INFO">정보</option>
              <option value="REPORT">오류 신고</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label" for="title">제목</label>
            <input type="text" class="form-input" id="title" name="boardTitle" maxlength="80" placeholder="제목을 입력하세요" required>
          </div>

          <div class="form-group">
            <label class="form-label" for="content">내용</label>
            <textarea class="form-input" id="boardContent" name="boardContent" rows="10" maxlength="2000" placeholder="내용을 입력하세요" required></textarea>
            <div class="form-hint">최소 10자 이상 작성해주세요.</div>
            <div class="char-count"><span id="charCount">0</span> / 2000</div>
          </div>

          <!-- <div class="form-group">
            <label class="form-label" for="images">이미지 첨부</label>
            <div class="upload-zone" id="uploadZone" role="button" tabindex="0" aria-label="이미지 파일 선택">
              <div class="upload-zone-icon">📎</div>
              <div class="upload-zone-text"><strong>클릭</strong>하거나 파일을 끌어다 놓으세요</div>
              <div class="upload-zone-hint">JPG, PNG, GIF · 최대 1장 · 10MB 이하</div>
              <input type="file" id="images" name="images" accept="image/*">
            </div>
            <div class="upload-preview-grid" id="uploadPreview"></div>
            <div class="upload-count" id="uploadCount"></div>
          </div> -->

          <div class="edit-actions">
            <a href="/board/list" class="btn btn-ghost">취소</a>
            <button type="submit" class="btn btn-primary">게시글 등록</button>
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

// 이미지 첨부 (최대 1장)
// const MAX_IMAGES = 1;
// const imagesInput = document.getElementById('images');
// const uploadZone = document.getElementById('uploadZone');
// const previewGrid = document.getElementById('uploadPreview');
// const uploadCountEl = document.getElementById('uploadCount');
// let attachedFiles = [];

// function updateUploadCount() {
//   uploadCountEl.textContent = attachedFiles.length > 0 ? `${attachedFiles.length}장 첨부됨` : '';
//   uploadZone.style.display = attachedFiles.length >= MAX_IMAGES ? 'none' : '';
// }

// function renderPreviews() {
//   previewGrid.innerHTML = '';
//   attachedFiles.forEach((file, idx) => {
//     const reader = new FileReader();
//     reader.onload = (e) => {
//       const item = document.createElement('div');
//       item.className = 'upload-preview-item';
//       item.innerHTML = `<img src="${e.target.result}" alt="${file.name}"><button type="button" class="upload-preview-remove" aria-label="이미지 삭제">✕</button>`;
//       item.querySelector('.upload-preview-remove').addEventListener('click', () => {
//         attachedFiles.splice(idx, 1);
//         renderPreviews();
//         updateUploadCount();
//       });
//       previewGrid.appendChild(item);
//     };
//     reader.readAsDataURL(file);
//   });
// }

// function addFiles(fileList) {
//   const incoming = Array.from(fileList).filter(f => f.type.startsWith('image/'));
//   const room = MAX_IMAGES - attachedFiles.length;
//   if (room <= 0) {
//     alert(`이미지는 최대 ${MAX_IMAGES}장까지 첨부할 수 있어요.`);
//     return;
//   }
//   attachedFiles = attachedFiles.concat(incoming.slice(0, room));
//   renderPreviews();
//   updateUploadCount();
// }

// imagesInput.addEventListener('change', (e) => {
//   addFiles(e.target.files);
//   imagesInput.value = '';
// });

// uploadZone.addEventListener('click', () => imagesInput.click());
// uploadZone.addEventListener('keydown', (e) => {
//   if (e.key === 'Enter' || e.key === ' ') {
//     e.preventDefault();
//     imagesInput.click();
//   }
// });
// uploadZone.addEventListener('dragover', (e) => {
//   e.preventDefault();
//   uploadZone.classList.add('dragover');
// });
// uploadZone.addEventListener('dragleave', () => uploadZone.classList.remove('dragover'));
// uploadZone.addEventListener('drop', (e) => {
//   e.preventDefault();
//   uploadZone.classList.remove('dragover');
//   addFiles(e.dataTransfer.files);
// });

</script>

</body>
</html>
