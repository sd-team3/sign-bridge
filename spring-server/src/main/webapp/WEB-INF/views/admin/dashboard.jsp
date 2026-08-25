<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="대시보드" scope="request" />
<c:set var="pageName" value="main" scope="request" />
<c:set var="activeMenu" value="dashboard" scope="request" />
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
    <div class="section-eyebrow">개요</div>
    <div class="section-hd">대시보드</div>
    <div class="section-sub">오늘 ${todayLabel} 기준 현황</div>
  </div>
</div>

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-icon" style="background:var(--p-light)">👥</div>
    <div class="stat-body">
      <div class="stat-label">전체 유저</div>
      <div class="stat-value">${totalUsers}</div>
      <div class="stat-delta delta-up">▲ +${newUsersToday} 오늘</div>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:var(--blue-light)">💬</div>
    <div class="stat-body">
      <div class="stat-label">전체 게시글</div>
      <div class="stat-value">${totalPosts}</div>
      <div class="stat-delta delta-up">▲ +${newBoardToday} 오늘</div>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:var(--rose-light)">🚨</div>
    <div class="stat-body">
      <div class="stat-label">오류 신고 (미처리)</div>
      <div class="stat-value">${errorCount}</div>
      <div class="stat-delta ${errorCount == 0 ? 'delta-up' : 'delta-down'}">
        <c:choose>
          <c:when test="${errorCount == 0}">
            ▲ 문제없음
          </c:when>
          <c:otherwise>
            ▼ 처리 필요
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </div>
</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px">
  <div class="card">
    <div class="card-title"><span class="ct-icon">📈</span> 주간 신규 가입자</div>
    <div class="mini-chart" id="mini-chart"></div>

    <div class="mini-chart" id="mini-chart" style="display:flex;align-items:flex-end;gap:6px;height:80px">
        <c:forEach var="count" items="${weeklySignups}">
            <div style="flex:1;background:var(--p);border-radius:4px 4px 0 0;
                        height:${weeklyMax == 0 ? 2 : (count * 100 / weeklyMax)}%;
                        min-height:2px;"
                title="${count}명"></div>
        </c:forEach>
    </div>

    <div style="display:flex;justify-content:space-between;margin-top:6px">
      <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">월</span>
      <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">화</span>
      <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">수</span>
      <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">목</span>
      <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">금</span>
      <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">토</span>
      <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">일</span>
    </div>
  </div>

  <div class="card">
    <div class="card-title"><span class="ct-icon">⚡</span> 카메라 모션 </div>
    <div class="feed">
      <a href="http://localhost:8000/">JAMO KSL 콘솔</a>
    </div>
  </div>
</div>

<jsp:include page="includes/footer.jsp" />
</body>
</html>
