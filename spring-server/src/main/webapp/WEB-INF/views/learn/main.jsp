<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 학습</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="learn-hero">
      <div class="learn-hero-text">
        <c:choose>
          <c:when test="${not empty memberName}">
            <h1>👋 ${memberName}님, 오늘도 함께 배워볼까요?</h1>
          </c:when>
          <c:otherwise>
            <h1>👋 오늘도 함께 배워볼까요?</h1>
          </c:otherwise>
        </c:choose>
        <p>꾸준한 학습이 실력을 만듭니다. 오늘의 목표를 채워보세요.</p>
      </div>
    </div>














    <div class="section-title">학습 카테고리</div>
    <div class="cat-grid">
      <a href="<c:url value='/learn/signs'/>" class="cat-card">
        <div class="cat-card-icon">📚</div>
        <div class="cat-card-title">챕터별 수어 학습</div>
        <div class="cat-card-desc">단어를 하나씩 익히고, 웹캠으로 따라 하며 동작 피드백을 받아요.</div>
      </a>
      <a href="/learn/jamo" class="cat-card">
        <div class="cat-card-icon">🤟</div>
        <div class="cat-card-title">자음 · 모음 지문자</div>
        <div class="cat-card-desc">수어의 기초, 지문자 ${jamoCount}개를 처음부터 차근차근 익혀요.</div>
      </a>































      <a href="/learn/dict" class="cat-card">
        <div class="cat-card-icon">🔍</div>
        <div class="cat-card-title">개별 어휘 검색</div>
        <div class="cat-card-desc">초성별로 찾거나 검색·수어 인식으로 원하는 단어를 학습하세요.</div>




      </a>

      <a href="/member/mypage" class="cat-card">
        <div class="cat-card-icon">📋</div>
        <div class="cat-card-title">나의 학습 기록</div>
        <div class="cat-card-desc">지금까지 학습한 단어와 정확도를 한눈에 확인해요.</div>
        <div class="cat-card-meta">
          <c:choose>
            <c:when test="${not empty lastLearningLabel}">
              <span style="font-size:13px; font-weight:700; color:var(--text-muted);">최근 학습: ${lastLearningLabel}</span>
            </c:when>
            <c:when test="${not empty memberName}">
              <span style="font-size:13px; font-weight:700; color:var(--text-muted);">아직 학습 기록이 없어요</span>
            </c:when>
            <c:otherwise>
              <span style="font-size:13px; font-weight:700; color:var(--text-muted);">로그인하면 기록이 저장돼요</span>
            </c:otherwise>
          </c:choose>
          <span class="cat-card-arrow">›</span>
        </div>
      </a>
    </div>


    <div class="play-banner">
      <div>
        <h3>🎮 배운 단어, 게임으로 복습해볼까요?</h3>
        <p>수어 끝말잇기와 디펜스 게임으로 재미있게 실력을 점검해보세요.</p>
      </div>
      <div class="play-banner-btns">
        <a href="/playzone/chain" class="btn btn-primary btn-sm">끝말잇기</a>
        <span class="btn btn-ghost btn-sm" style="border-color:rgba(255,255,255,.3); color:rgba(255,255,255,.5); cursor:not-allowed; opacity:.6;" aria-disabled="true">디펜스 모드 (준비중)</span>
      </div>
    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

</body>
</html>
