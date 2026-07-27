<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="단어 추가 요청 확인" scope="request" />
<c:set var="pagePath" value="/admin/question/add" scope="request" />
<c:set var="activeMenu" value="question-add" scope="request" />
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - ${pageTitle}</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/resources/css/admin.css">
</head>
<body>

<jsp:include page="includes/header.jsp" />


<div class="page-header">
  <div>
    <div class="section-eyebrow">문의 / 신고</div>
    <div class="section-hd">단어 추가 요청 확인</div>
    <div class="section-sub">미처리 요청 ${pendingRequestCount}건이 있습니다</div>
  </div>
</div>

<div class="tabs">
  <a href="?status=pending" class="tab ${param.status == 'pending' || empty param.status ? 'active' : ''}">미처리 <span class="pill pill-amber" style="margin-left:4px;padding:1px 7px">${pendingRequestCount}</span></a>
  <a href="?status=approved" class="tab ${param.status == 'approved' ? 'active' : ''}">승인됨</a>
  <a href="?status=rejected" class="tab ${param.status == 'rejected' ? 'active' : ''}">거절됨</a>
</div>

<div style="display:flex;flex-direction:column;gap:12px">
  <c:forEach var="req" items="${wordRequestList}">
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px">
        <div>
          <div style="font-size:13px;color:var(--ink3);margin-bottom:4px"><b>${req.requester}</b> · ${req.createdAt}</div>
          <div style="font-size:14px;font-weight:600;color:var(--ink);margin-bottom:6px">"${req.wordText}" 단어 추가 요청</div>
          <div style="font-size:13px;color:var(--ink3)">${req.reason}</div>
        </div>
        <span class="pill ${req.statusPillClass}">${req.statusLabel}</span>
      </div>
      <c:if test="${req.statusLabel == '미처리'}">
        <div style="display:flex;gap:8px;margin-top:12px">
          <form method="post" action="${pageContext.request.contextPath}/admin/question/add/approve" style="display:inline">
            <input type="hidden" name="requestId" value="${req.id}">
            <button type="submit" class="topbar-btn btn-primary" style="padding:5px 12px;font-size:12px">승인</button>
          </form>
          <form method="post" action="${pageContext.request.contextPath}/admin/question/add/reject" style="display:inline">
            <input type="hidden" name="requestId" value="${req.id}">
            <button type="submit" class="topbar-btn btn-ghost" style="padding:5px 12px;font-size:12px">거절</button>
          </form>
        </div>
      </c:if>
    </div>
  </c:forEach>
</div>

<jsp:include page="includes/footer.jsp" />
</body>
</html>
