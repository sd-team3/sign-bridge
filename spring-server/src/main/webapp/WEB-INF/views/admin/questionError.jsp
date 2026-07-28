<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="오류 신고 확인" scope="request" />
<c:set var="pagePath" value="/admin/question/error" scope="request" />
<c:set var="activeMenu" value="question-error" scope="request" />
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
    <div class="section-hd">오류 신고 확인</div>
    <div class="section-sub">미처리 신고 ${pendingErrorCount}건이 있습니다</div>
  </div>
</div>

<div class="tabs">
  <a href="?status=pending" class="tab ${param.status == 'pending' || empty param.status ? 'active' : ''}">미처리 <span class="pill pill-red" style="margin-left:4px;padding:1px 7px">${pendingErrorCount}</span></a>
  <a href="?status=done" class="tab ${param.status == 'done' ? 'active' : ''}">처리 완료</a>
  <a href="?status=all" class="tab ${param.status == 'all' ? 'active' : ''}">전체</a>
</div>

<div style="display:flex;flex-direction:column;gap:12px">
  <c:forEach var="err" items="${errorReportList}">
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px">
        <div>
          <div style="font-size:13px;color:var(--ink3);margin-bottom:4px"><b>${err.reporter}</b> · ${err.createdAt}</div>
          <div style="font-size:14px;font-weight:600;color:var(--ink);margin-bottom:6px">"${err.wordText}" 단어 인식 오류</div>
          <div style="font-size:13px;color:var(--ink3)">${err.description}</div>
        </div>
        <span class="pill ${err.statusPillClass}">${err.statusLabel}</span>
      </div>
      <c:if test="${err.statusLabel == '미처리'}">
        <div style="display:flex;gap:8px;margin-top:12px">
          <form method="post" action="${pageContext.request.contextPath}/admin/question/error/resolve" style="display:inline">
            <input type="hidden" name="reportId" value="${err.id}">
            <button type="submit" class="topbar-btn btn-primary" style="padding:5px 12px;font-size:12px">처리 완료</button>
          </form>
          <a href="${pageContext.request.contextPath}/admin/word/update?keyword=${err.wordText}" class="topbar-btn btn-ghost" style="padding:5px 12px;font-size:12px">단어 수정하러 가기</a>
        </div>
      </c:if>
    </div>
  </c:forEach>
</div>

<jsp:include page="includes/footer.jsp" />
</body>
</html>
