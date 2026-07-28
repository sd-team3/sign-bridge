<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="단어 수정" scope="request" />
<c:set var="pagePath" value="/admin/word/update" scope="request" />
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
    <div class="section-hd">단어 수정</div>
    <div class="section-sub">기존 단어 정보를 수정합니다</div>
  </div>
</div>

<div class="card" style="margin-bottom:16px">
  <div class="card-title"><span class="ct-icon">🔍</span> 단어 검색</div>
  <form class="filter-bar" style="margin-bottom:0" method="get" action="${pageContext.request.contextPath}/admin/word/update">
    <div class="search-wrap">
      <span class="si">🔍</span>
      <input type="text" name="keyword" value="${param.keyword}" placeholder="수정할 단어 검색...">
    </div>
    <select class="filter-select" name="category">
      <option value="">전체 카테고리</option>
      <option value="basic" ${param.category == 'basic' ? 'selected' : ''}>기초 어휘</option>
      <option value="emergency" ${param.category == 'emergency' ? 'selected' : ''}>비상 상황</option>
    </select>
    <button type="submit" class="topbar-btn btn-primary">검색</button>
  </form>
</div>

<c:if test="${not empty word}">
  <div class="card">
    <div class="card-title">
      <span class="ct-icon">✏️</span> 수정: "${word.word}"
      <span class="pill pill-green" style="margin-left:4px">${word.categoryLabel}</span>
    </div>
    <form class="form-grid" method="post" action="${pageContext.request.contextPath}/admin/word/update">
      <input type="hidden" name="wordId" value="${word.id}">
      <div class="form-row">
        <label class="fl">단어 (한글)</label>
        <input class="fi" type="text" name="word" value="${word.word}">
      </div>
      <div class="form-row">
        <label class="fl">카테고리</label>
        <select class="fi" name="category">
          <option value="basic" ${word.category == 'basic' ? 'selected' : ''}>기초 어휘</option>
          <option value="emergency" ${word.category == 'emergency' ? 'selected' : ''}>비상 상황</option>
        </select>
      </div>
      <div class="form-row">
        <label class="fl">난이도</label>
        <select class="fi" name="level">
          <option value="beginner" ${word.level == 'beginner' ? 'selected' : ''}>초급</option>
          <option value="intermediate" ${word.level == 'intermediate' ? 'selected' : ''}>중급</option>
          <option value="advanced" ${word.level == 'advanced' ? 'selected' : ''}>고급</option>
        </select>
      </div>
      <div class="form-row">
        <label class="fl">중요도 태그</label>
        <select class="fi" name="importance">
          <option value="essential" ${word.importance == 'essential' ? 'selected' : ''}>필수</option>
          <option value="normal" ${word.importance == 'normal' ? 'selected' : ''}>일반</option>
          <option value="emergency" ${word.importance == 'emergency' ? 'selected' : ''}>비상</option>
        </select>
      </div>
      <div class="form-row full">
        <label class="fl">동영상 URL</label>
        <input class="fi" type="text" name="videoUrl" value="${word.videoUrl}">
      </div>
      <div class="form-row full">
        <label class="fl">설명 / 메모</label>
        <textarea class="fi" name="memo">${word.memo}</textarea>
      </div>
      <div class="form-actions">
        <button type="submit" class="topbar-btn btn-primary">💾 저장</button>
        <a href="${pageContext.request.contextPath}/admin/word/update" class="topbar-btn btn-ghost">취소</a>
      </div>
    </form>
  </div>
</c:if>

<jsp:include page="includes/footer.jsp" />
</body>
</html>
