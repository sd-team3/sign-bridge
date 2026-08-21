<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<meta name="_csrf" content="${_csrf.token}">
<meta name="_csrf_header" content="${_csrf.headerName}">
<title>SignBridge 관리자 - 문의 확인</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/resources/css/admin.css">
</head>
<body>

<jsp:include page="includes/header.jsp" />

  <!-- ══════════ PAGE: 문의 확인 ══════════ -->
  <div class="content page active" id="page-question-error">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">문의 / 신고</div>
        <div class="section-hd">
          <c:choose>
            <c:when test="${currentCategory == 'ERROR_REPORT'}">오류 신고 확인</c:when>
            <c:when test="${currentCategory == 'ACCOUNT'}">계정 문의 확인</c:when>
            <c:when test="${currentCategory == 'GENERAL'}">일반 문의 확인</c:when>
            <c:otherwise>문의 확인</c:otherwise>
          </c:choose>
        </div>
        <div class="section-sub">
          <c:choose>
            <c:when test="${currentStatus == 'PROCESSING'}">처리중 ${processingCount}건이 있습니다</c:when>
            <c:when test="${currentStatus == 'COMPLETE'}">완료 ${fn:length(inquiryList)}건이 있습니다</c:when>
            <c:when test="${currentStatus == 'ALL'}">전체 ${fn:length(inquiryList)}건이 있습니다</c:when>
            <c:otherwise>대기 ${waitCount}건이 있습니다</c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>

    <!-- 상태 탭: 서버사이드 필터링 (category, status 파라미터로 재조회) -->
    <div class="tabs">
      <a href="?category=${currentCategory}&status=WAIT" class="tab ${currentStatus == 'WAIT' ? 'active' : ''}">
        대기 <span class="pill pill-red" style="margin-left:4px;padding:1px 7px">${waitCount}</span>
      </a>
      <a href="?category=${currentCategory}&status=COMPLETE" class="tab ${currentStatus == 'COMPLETE' ? 'active' : ''}">완료</a>
      <a href="?category=${currentCategory}&status=ALL" class="tab ${currentStatus == 'ALL' ? 'active' : ''}">전체</a>
    </div>

    <div style="display:flex;flex-direction:column;gap:12px" id="error-list">
      <c:forEach var="inq" items="${inquiryList}">
        <div class="card" style="display:flex;align-items:flex-start;gap:16px;flex-wrap:wrap">
          <div style="flex:1;min-width:240px">
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px">
              <c:choose>
                <c:when test="${inq.status == 'WAIT'}">
                  <span class="pill pill-red">대기</span>
                </c:when>
                <c:otherwise>
                  <span class="pill pill-green">완료</span>
                </c:otherwise>
              </c:choose>
              <span class="td-mono" style="font-size:12px;color:var(--ink3)">#${inq.inquiryId}</span>
              <span style="font-size:12px;color:var(--ink3)">
                · ${inq.regDateStr} · ${inq.memberName}
              </span>
            </div>
            <div style="font-size:15px;font-weight:700;margin-bottom:4px">${inq.title}</div>
            <div style="font-size:13px;color:var(--ink2)">${inq.content}</div>

            <c:if test="${not empty inq.answerContent}">
              <div class="original-box" style="margin-top:8px;background:#eef7f1">
                <b>답변:</b> ${inq.answerContent}
              </div>
            </c:if>
          </div>
          <div style="display:flex;gap:6px;flex-shrink:0;align-items:center">
            <c:if test="${inq.status != 'COMPLETE'}">
              <button class="topbar-btn btn-primary btn-sm"
                      data-action="answer"
                      data-id="${inq.inquiryId}"
                      data-title="${inq.title}"
                      data-content="${inq.content}">답변하기</button>
            </c:if>
          </div>
        </div>
      </c:forEach>

      <c:if test="${empty inquiryList}">
        <div style="text-align:center;color:var(--ink3);padding:40px 0">신고 내역이 없습니다</div>
      </c:if>
    </div>
  </div>

<!-- ═══════════ ANSWER MODAL ═══════════ -->
<div class="modal-backdrop" id="answer-modal">
  <div class="modal-box">
    <h3>문의 답변</h3>
    <div class="modal-sub" id="answer-target-title"></div>
    <div class="original-box" id="answer-target-content"></div>
    <div class="modal-field">
      <label>답변 내용</label>
      <textarea id="answer-content" placeholder="처리 결과 또는 안내 내용을 입력하세요"></textarea>
    </div>
    <div class="modal-actions">
      <button class="topbar-btn btn-ghost btn-sm" id="answer-cancel">취소</button>
      <button class="topbar-btn btn-primary btn-sm" id="answer-submit">답변 등록 (완료 처리)</button>
    </div>
  </div>
</div>

<!-- TOAST CONTAINER -->
<div class="toast-wrap" id="toast-wrap"></div>

<jsp:include page="includes/footer.jsp" />

<script>
let targetInquiryId = null;

// ═══════════ TOAST ═══════════
function showToast(msg,color='#2d9b6f'){
  const wrap=document.getElementById('toast-wrap');
  const t=document.createElement('div');
  t.className='toast';
  t.innerHTML = '<div class="toast-dot" style="background:' + color + '"></div>' + msg;
  wrap.appendChild(t);
  requestAnimationFrame(()=>requestAnimationFrame(()=>t.classList.add('show')));
  setTimeout(()=>{t.classList.remove('show');setTimeout(()=>t.remove(),350)},2800);
}

// ═══════════ MODAL ═══════════
function openAnswerModal(btn){
  targetInquiryId = btn.dataset.id;
  document.getElementById('answer-target-title').textContent = btn.dataset.title;
  document.getElementById('answer-target-content').textContent = btn.dataset.content;
  document.getElementById('answer-content').value = '';
  document.getElementById('answer-modal').classList.add('show');
}

function closeAnswerModal(){
  targetInquiryId = null;
  document.getElementById('answer-modal').classList.remove('show');
}

// ═══════════ 답변 등록 ═══════════
async function submitAnswer(){
  const content = document.getElementById('answer-content').value.trim();
  if (!content) {
    showToast('답변 내용을 입력해주세요', '#c0392b');
    return;
  }
  const csrfToken = document.querySelector('meta[name="_csrf"]').content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;
  try {
    const res = await fetch('/admin/inquiry/answer', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', [csrfHeader]: csrfToken },
      body: JSON.stringify({
        inquiryId: targetInquiryId,
        answerContent: content
      })
    });
    if (!res.ok) throw new Error('요청 실패');

    showToast('답변이 등록되었습니다 ✓', '#2d9b6f');
    closeAnswerModal();
    setTimeout(() => location.reload(), 600);
  } catch (err) {
    showToast('답변 등록에 실패했습니다', '#c0392b');
  }
}
// ═══════════ EVENT LISTENERS ═══════════
document.getElementById('error-list').addEventListener('click', (e) => {
  const btn = e.target.closest('button[data-action="answer"]');
  if (!btn) return;
  openAnswerModal(btn);
});

document.getElementById('answer-cancel').addEventListener('click', closeAnswerModal);
document.getElementById('answer-submit').addEventListener('click', submitAnswer);

document.getElementById('answer-modal').addEventListener('click', (e) => {
  if (e.target.id === 'answer-modal') closeAnswerModal();
});
</script>
</body>
</html>