<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
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
      </div>

      <div class="card">
        <form id="writeForm" action="/board/write" method="post" enctype="multipart/form-data">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
          <div class="form-group">
            <label class="form-label" for="category">카테고리</label>
              <select class="form-input" id="category" name="categoryIdx" required>
                <option value="" ${empty param.category ? 'selected' : ''} disabled>카테고리를 선택하세요</option>
                <c:if test="${isAdmin}">
                  <option value="NOTICE" ${param.category == 'NOTICE' ? 'selected' : ''}>공지</option>
                </c:if>
                <option value="QNA" ${param.category == 'QNA' ? 'selected' : ''}>질문</option>
                <option value="FREE" ${param.category == 'FREE' ? 'selected' : ''}>자유</option>
                <option value="INFO" ${param.category == 'INFO' ? 'selected' : ''}>정보</option>
                <option value="REPORT" ${param.category == 'REPORT' ? 'selected' : ''}>오류 신고</option>
              </select>
          </div>
          <!-- 신고 카테고리 한정 -->
          <div class="form-group report-extra-fields" id="reportExtraFields" style="display:none;">
            <label class="form-label" for="errorType">오류 유형</label>
            <select id="errorType" name="errorType" class="form-input">
              <option value="ACTION_RECOGNITION">동작 인식 오류</option>
              <option value="VIDEO_PLAYBACK">영상 재생 오류</option>
              <option value="TRANSLATION">번역 · 뜻풀이 오류</option>
              <option value="UI_BUG">화면 · 디자인 오류</option>
              <option value="ETC">기타</option>
            </select>
            <div class="form-hint">문제 유형을 선택해주시면 확인이 빨라져요.</div>
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

          <div class="form-group">
            <label class="form-label" for="files">이미지 · 영상 첨부</label>
            <div class="upload-zone" id="uploadZone" role="button" tabindex="0" aria-label="파일 선택">
              <div class="upload-zone-icon">📎</div>
              <div class="upload-zone-text"><strong>클릭</strong>하거나 파일을 끌어다 놓으세요</div>
              <div class="upload-zone-hint">JPG, PNG, GIF, WEBP, MP4, WEBM · 최대 5개 · 개당 100MB 이하</div>
              <input type="file" id="filesInput" name="files" accept="image/*,video/*" multiple style="display:none;">
            </div>
            <div class="upload-preview-grid" id="uploadPreview"></div>
            <div class="upload-count" id="uploadCount"></div>
          </div>

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

const MAX_FILES = 5;
const filesInput = document.getElementById('filesInput');
const uploadZone = document.getElementById('uploadZone');
const previewGrid = document.getElementById('uploadPreview');
const uploadCountEl = document.getElementById('uploadCount');
let attachedFiles = [];

function updateUploadCount() {
  uploadCountEl.textContent = attachedFiles.length > 0 ? (attachedFiles.length + '개 첨부됨') : '';
}

function renderPreviews() {
  previewGrid.innerHTML = '';
  attachedFiles.forEach((file, idx) => {
    const isVideo = file.type.startsWith('video/');
    const url = URL.createObjectURL(file);

    const item = document.createElement('div');
    item.className = 'upload-preview-item';
    item.innerHTML = isVideo
      ? '<video src="' + url + '" muted></video><button type="button" class="upload-preview-remove">✕</button>'
      : '<img src="' + url + '" alt="' + file.name + '"><button type="button" class="upload-preview-remove">✕</button>';

    item.querySelector('.upload-preview-remove').addEventListener('click', () => {
      URL.revokeObjectURL(url);
      attachedFiles.splice(idx, 1);
      syncInputFiles();
      renderPreviews();
      updateUploadCount();
    });
    previewGrid.appendChild(item);
  });
}

function addFiles(fileList) {
  const incoming = Array.from(fileList).filter(f => f.type.startsWith('image/') || f.type.startsWith('video/'));
  const room = MAX_FILES - attachedFiles.length;
  if (room <= 0) {
    alert('파일은 최대 ' + MAX_FILES + '개까지 첨부할 수 있어요.');
    return;
  }
  attachedFiles = attachedFiles.concat(incoming.slice(0, room));
  syncInputFiles();
  renderPreviews();
  updateUploadCount();
}

function syncInputFiles() {
  const dt = new DataTransfer();
  attachedFiles.forEach(f => dt.items.add(f));
  filesInput.files = dt.files;
}

filesInput.addEventListener('change', (e) => addFiles(e.target.files));
uploadZone.addEventListener('click', () => filesInput.click());
uploadZone.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); filesInput.click(); }
});
uploadZone.addEventListener('dragover', (e) => { e.preventDefault(); uploadZone.classList.add('dragover'); });
uploadZone.addEventListener('dragleave', () => uploadZone.classList.remove('dragover'));
uploadZone.addEventListener('drop', (e) => {
  e.preventDefault();
  uploadZone.classList.remove('dragover');
  addFiles(e.dataTransfer.files);
});

const categorySelect = document.getElementById('category');
const reportExtraFields = document.getElementById('reportExtraFields');
const errorTypeSelect = document.getElementById('errorType');

function toggleReportFields() {
  const isReport = categorySelect.value === 'REPORT';
  reportExtraFields.style.display = isReport ? 'block' : 'none';
  errorTypeSelect.required = isReport; // REPORT일 때만 필수 처리
}

categorySelect.addEventListener('change', toggleReportFields);
toggleReportFields();

</script>

</body>
</html>
