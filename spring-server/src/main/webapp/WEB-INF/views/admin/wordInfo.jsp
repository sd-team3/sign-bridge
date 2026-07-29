<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="단어 상세" scope="request" />
<c:set var="pagePath" value="/admin/word/info" scope="request" />
<c:set var="activeMenu" value="word-update" scope="request" />
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
    <div class="section-eyebrow">단어 관리</div>
    <div class="section-hd">단어 상세 / 수정</div>
    <div class="section-sub">단어 정보를 확인하고 수정합니다</div>
  </div>
</div>

<c:if test="${not empty word}">
  <div class="card">
    <div class="card-title">
      <span class="ct-icon">✏️</span> 수정: "${word.signWordName}"
      <span class="pill" style="margin-left:4px">조회수 ${word.viewCount}</span>
    </div>
    <form class="form-grid" method="post" action="${pageContext.request.contextPath}/admin/word/update">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
      <input type="hidden" name="signWordId" value="${word.signWordId}">

      <div class="form-row">
        <label class="fl">단어명</label>
        <input class="fi" type="text" name="signWordName" value="${word.signWordName}">
      </div>

      <div class="form-row">
        <label class="fl">초성</label>
        <input class="fi" type="text" name="choseong" value="${word.choseong}">
      </div>

      <div class="form-row full">
        <label class="fl">영상 URL</label>
        <input class="fi" type="text" name="signWordVideo" value="${word.signWordVideo}">
      </div>

      <div class="form-row full">
        <label class="fl">썸네일 URL</label>
        <input class="fi" type="text" name="signWordThumbnail" value="${word.signWordThumbnail}">
      </div>

      <div class="form-row full">
        <label class="fl">설명</label>
        <textarea class="fi" name="description">${word.description}</textarea>
      </div>

      <div class="form-row">
        <label class="fl">API ID</label>
        <input class="fi" type="text" value="${word.signWordApiId}" readonly>
      </div>

      <div class="form-row">
        <label class="fl">조회수</label>
        <input class="fi" type="text" value="${word.viewCount}" readonly>
      </div>

      <div class="form-actions">
        <button type="submit" class="topbar-btn btn-primary">💾 저장</button>
        <a href="${pageContext.request.contextPath}/admin/word/update" class="topbar-btn btn-ghost">목록으로</a>
      </div>
    </form>
  </div>
</c:if>

<jsp:include page="includes/footer.jsp" />
</body>
</html>