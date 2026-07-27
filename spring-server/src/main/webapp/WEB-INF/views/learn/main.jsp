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
    <!-- 상단 요약 배너 -->
    <div class="learn-hero">
      <div class="learn-hero-text">
        <h1>👋 홍길동님, 오늘도 함께 배워볼까요?</h1>
        <p>꾸준한 학습이 실력을 만듭니다. 오늘의 목표를 채워보세요.</p>
      </div>
      <div class="learn-hero-stats">
        <div class="lh-stat"><div class="lh-stat-num">42</div><div class="lh-stat-lbl">학습한 단어</div></div>
        <div class="lh-stat"><div class="lh-stat-num">87%</div><div class="lh-stat-lbl">평균 정확도</div></div>
        <div class="lh-stat"><div class="lh-stat-num">7일</div><div class="lh-stat-lbl">연속 학습</div></div>
      </div>
    </div>

    <!-- 이어하기 -->
    <div class="continue-banner">
      <div class="cb-left">
        <div class="cb-icon">🍎</div>
        <div>
          <div class="cb-title">기초 어휘 · '사과' 이어서 학습하기</div>
          <div class="cb-sub">최근 정확도 94% · 다음 단어까지 3개 남음</div>
        </div>
      </div>
      <a href="learn_word_detail.html" class="btn btn-primary btn-sm">이어서 하기 →</a>
    </div>

    <!-- 카테고리 -->
    <div class="section-title">학습 카테고리</div>
    <div class="cat-grid">
      <a href="/" class="cat-card">
        <span class="cat-card-new">NEW</span>
        <div class="cat-card-icon">🤟</div>
        <div class="cat-card-title">자음 · 모음 지문자</div>
        <div class="cat-card-desc">수어의 기초, 지문자 24개를 처음부터 차근차근 익혀요.</div>
        <div class="cat-card-meta">
          <div class="cat-card-progress"><div class="prog-track"><div class="prog-fill" style="width:15%"></div></div></div>
          <span class="cat-card-pct">15%</span>
        </div>
      </a>

      <!-- <a href="learn_basic.html" class="cat-card">
        <div class="cat-card-icon">📚</div>
        <div class="cat-card-title">기초 어휘 학습</div>
        <div class="cat-card-desc">일상에서 자주 쓰는 기본 단어 124개를 분야별로 학습해요.</div>
        <div class="cat-card-meta">
          <div class="cat-card-progress"><div class="prog-track"><div class="prog-fill" style="width:68%"></div></div></div>
          <span class="cat-card-pct">68%</span>
        </div>
      </a> -->

      <!-- <a href="learn_list.html" class="cat-card purple">
        <div class="cat-card-icon">🗂️</div>
        <div class="cat-card-title">상황별 수어 학습</div>
        <div class="cat-card-desc">인사, 학교, 자연 등 35개 주제로 구성된 상황별 회화 수업.</div>
        <div class="cat-card-meta">
          <div class="cat-card-progress"><div class="prog-track"><div class="prog-fill" style="width:22%"></div></div></div>
          <span class="cat-card-pct">22%</span>
        </div>
      </a> -->

      <!-- <a href="learn_emergency.html" class="cat-card danger">
        <div class="cat-card-icon">🚨</div>
        <div class="cat-card-title">비상 상황 어휘</div>
        <div class="cat-card-desc">화재, 지진, 응급 상황에서 꼭 필요한 핵심 수어를 배워요.</div>
        <div class="cat-card-meta">
          <div class="cat-card-progress"><div class="prog-track"><div class="prog-fill" style="width:35%"></div></div></div>
          <span class="cat-card-pct">35%</span>
        </div>
      </a> -->

      <a href="/learn/dict" class="cat-card">
        <div class="cat-card-icon">🔍</div>
        <div class="cat-card-title">개별 어휘 검색</div>
        <div class="cat-card-desc">원하는 단어를 검색하거나 분야별 필터로 자유롭게 학습해요.</div>
        <div class="cat-card-meta">
          <span style="font-size:13px; font-weight:700; color:var(--text-muted);">총 124개 단어</span>
          <span class="cat-card-arrow">›</span>
        </div>
      </a>

      <a href="mypage_history.html" class="cat-card">
        <div class="cat-card-icon">📋</div>
        <div class="cat-card-title">나의 학습 기록</div>
        <div class="cat-card-desc">지금까지 학습한 단어와 정확도를 한눈에 확인해요.</div>
        <div class="cat-card-meta">
          <span style="font-size:13px; font-weight:700; color:var(--text-muted);">최근 학습: 오늘</span>
          <span class="cat-card-arrow">›</span>
        </div>
      </a>
    </div>

    <!-- 플레이존 유도 배너 -->
    <div class="play-banner">
      <div>
        <h3>🎮 배운 단어, 게임으로 복습해볼까요?</h3>
        <p>수어 끝말잇기와 디펜스 게임으로 재미있게 실력을 점검해보세요.</p>
      </div>
      <div class="play-banner-btns">
        <a href="play_chain.html" class="btn btn-primary btn-sm">끝말잇기</a>
        <a href="play_defense.html" class="btn btn-ghost btn-sm" style="border-color:rgba(255,255,255,.3); color:rgba(255,255,255,.85);">디펜스 모드</a>
      </div>
    </div>
  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

</body>
</html>
