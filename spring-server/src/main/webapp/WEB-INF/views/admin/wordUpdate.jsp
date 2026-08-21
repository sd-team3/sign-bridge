<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="pageTitle" value="단어 수정" scope="request" />
<c:set var="pagePath" value="/admin/word/update" scope="request" />
<c:set var="activeMenu" value="word-update" scope="request" />
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
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
    <button type="submit" class="topbar-btn btn-primary">검색</button>
  </form>
</div>

<div class="table-wrap">
  <table id="user-table">
    <thead>
      <tr>
        <th>단어ID</th>
        <th>단어</th>
        <th>설명</th>
        <th>상세</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="word" items="${words}">
        <tr>
          <td class="td-mono">${word.signWordId}</td>
          <td>${word.signWordName}</td>
          <td>
            ${fn:length(word.description) > 20
                ? fn:substring(word.description, 0, 7).concat('...') 
                : word.description}
          </td>
          <td><a href="/admin/word/info?signWordId=${word.signWordId}" class="topbar-btn btn-ghost" style="padding:4px 10px;font-size:12px">상세</a></td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
</div>

  <div class="pagination">
    <a class="pg-btn" href="/admin/word?page=${pageBean.prevPage}">‹</a>
    <c:forEach var="p" begin="${pageBean.min}" end="${pageBean.max}">
      <a class="pg-btn ${p == pageBean.currentPage ? 'active' : ''}" href="/admin/word?page=${p}">${p}</a>
    </c:forEach>
    <a class="pg-btn" href="/admin/word?page=${pageBean.nextPage}">›</a>
  </div>

<jsp:include page="includes/footer.jsp" />
</body>
</html>
