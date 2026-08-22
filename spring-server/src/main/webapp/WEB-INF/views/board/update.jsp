<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
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
        <form id="editForm" action="/board/update" method="post" enctype="multipart/form-data">
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

          <!-- 신고 카테고리 한정 -->
          <div class="form-group report-extra-fields" id="reportExtraFields" style="display:none;">
            <label class="form-label" for="errorType">오류 유형</label>
            <select id="errorType" name="errorType" class="form-input">
              <option value="ACTION_RECOGNITION" ${errorType == 'ACTION_RECOGNITION' ? 'selected' : ''}>동작 인식 오류</option>
              <option value="VIDEO_PLAYBACK" ${errorType == 'VIDEO_PLAYBACK' ? 'selected' : ''}>영상 재생 오류</option>
              <option value="TRANSLATION" ${errorType == 'TRANSLATION' ? 'selected' : ''}>번역 · 뜻풀이 오류</option>
              <option value="UI_BUG" ${errorType == 'UI_BUG' ? 'selected' : ''}>화면 · 디자인 오류</option>
              <option value="ETC" ${errorType == 'ETC' ? 'selected' : ''}>기타</option>
            </select>
            <div class="form-hint">문제 유형을 선택해주시면 확인이 빨라져요.</div>
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

          <div class="form-group">
            <label class="form-label">기존 첨부파일</label>
            <div class="upload-preview-grid" id="existingFiles">
              <c:forEach var="f" items="${boardFiles}">
                <div class="upload-preview-item" data-file-id="${f.boardFileId}">
                  <c:choose>
                    <c:when test="${f.fileType == 'IMAGE'}">
                      <img src="${f.filePath}" alt="${f.origName}">
                    </c:when>
                    <c:otherwise>
                      <video src="${f.filePath}" muted></video>
                    </c:otherwise>
                  </c:choose>
                  <button type="button" class="upload-preview-remove"
                    onclick="markExistingFileForDelete(${f.boardFileId}, this)">✕</button>
                </div>
              </c:forEach>
            </div>
            <c:if test="${empty boardFiles}">
              <div class="form-hint">첨부된 파일이 없어요.</div>
            </c:if>
          </div>

          <div class="form-group">
            <label class="form-label" for="files">새 이미지 · 영상 첨부</label>
            <div class="upload-zone" id="uploadZone" role="button" tabindex="0" aria-label="파일 선택">
              <div class="upload-zone-icon">📎</div>
              <div class="upload-zone-text"><strong>클릭</strong>하거나 파일을 끌어다 놓으세요</div>
              <div class="upload-zone-hint">JPG, PNG, GIF, WEBP, MP4, WEBM · 최대 5개 · 개당 100MB 이하</div>
              <input type="file" id="filesInput" name="files" accept="image/*,video/*" multiple style="display:none;">
            </div>
            <div class="upload-preview-grid" id="uploadPreview"></div>
            <div class="upload-count" id="uploadCount"></div>
          </div>

          <div id="deleteFileIdsContainer"></div>

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

const categorySelect = document.getElementById('category');
const reportExtraFields = document.getElementById('reportExtraFields');
const errorTypeSelect = document.getElementById('errorType');

function toggleReportFields() {
  const isReport = categorySelect.value === 'REPORT';
  reportExtraFields.style.display = isReport ? 'block' : 'none';
  errorTypeSelect.required = isReport;
}

categorySelect.addEventListener('change', toggleReportFields);
toggleReportFields();

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

function syncInputFiles() {
  const dt = new DataTransfer();
  attachedFiles.forEach(f => dt.items.add(f));
  filesInput.files = dt.files;
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

// 기존 첨부파일 삭제 마킹
function markExistingFileForDelete(fileId, btn) {
  const item = btn.closest('.upload-preview-item');
  item.remove();
  const hidden = document.createElement('input');
  hidden.type = 'hidden';
  hidden.name = 'deleteFileIds';
  hidden.value = fileId;
  document.getElementById('deleteFileIdsContainer').appendChild(hidden);
}
</script>

</body>
</html>
