<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="pageTitle" value="유저 목록" scope="request" />
<c:set var="pageName" value="userList" scope="request" />
<c:set var="activeMenu" value="user-list" scope="request" />
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
    <div class="section-eyebrow">사용자 관리</div>
    <div class="section-hd">유저 목록</div>
  </div>
</div>

<form class="filter-bar" method="get" action="/admin/user/list">
  <div class="search-wrap">
    <span class="si">🔍</span>
    <input type="text" name="keyword" value="${param.keyword}" placeholder="이름, 이메일, UID 검색...">
  </div>
  <select class="filter-select" name="filterType" onchange="this.form.submit()">
    <option value="">전체 역할</option>
    <option value="role:USER" ${param.filterType == 'role:USER' ? 'selected' : ''}>일반 유저</option>
    <option value="status:SUSPENDED" ${param.filterType == 'status:SUSPENDED' ? 'selected' : ''}>정지됨</option>
    <option value="role:ADMIN" ${param.filterType == 'role:ADMIN' ? 'selected' : ''}>관리자</option>
  </select>
  <select class="filter-select" name="sort" onchange="this.form.submit()">
    <option value="newest" ${param.sort == 'newest' || empty param.sort ? 'selected' : ''}>가입일 최신순</option>
    <option value="oldest" ${param.sort == 'oldest' ? 'selected' : ''}>가입일 오래된순</option>
    <option value="name" ${param.sort == 'name' ? 'selected' : ''}>이름순</option>
  </select>
</form>

<div class="table-wrap">
  <table id="user-table">
    <thead>
      <tr>
        <th>UID</th>
        <th>이름</th>
        <th>이메일</th>
        <th>역할</th>
        <th>가입일</th>
        <th>상태</th>
        <th>정지 기간</th>
        <th>작업</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="user" items="${userList}">
        <tr>
          <td class="td-mono">${user.memberId}</td>
          <td>${user.memberName}</td>
          <td>${user.memberEmail}</td>
          <td>${user.role}</td>
          <td class="td-mono">${fn:substring(user.regDate, 0, 10)}</td>
          <td><span class="pill ${user.status}">${user.status}</span></td>
          <td>
            <c:if test="${user.status == 'SUSPENDED'}">
              <span class="badge badge-danger">
                정지
                <c:choose>
                  <c:when test="${user.suspendEndDate == null}">(영구)</c:when>
                  <c:otherwise>(~<fmt:formatDate value="${user.suspendEndDate}" pattern="yyyy-MM-dd"/>)</c:otherwise>
                </c:choose>
              </span>
            </c:if>
          </td>
          <td><a href="/admin/user/info?memberId=${user.memberId}" class="topbar-btn btn-ghost" style="padding:4px 10px;font-size:12px">상세</a></td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
</div>

  <div class="pagination">
    <a class="pg-btn" href="/admin/member?page=${pageBean.prevPage}&role=${user.role}">‹</a>
    <c:forEach var="p" begin="${pageBean.min}" end="${pageBean.max}">
      <a class="pg-btn ${p == pageBean.currentPage ? 'active' : ''}" href="/admin/member?page=${p}&role=${param.role}">${p}</a>
    </c:forEach>
    <a class="pg-btn" href="/admin/member?page=${pageBean.nextPage}&role=${param.role}">›</a>
  </div>

<jsp:include page="includes/footer.jsp" />
</body>
</html>
