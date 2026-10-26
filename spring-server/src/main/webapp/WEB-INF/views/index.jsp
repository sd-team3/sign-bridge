<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SignBridge — 수어로 가까워지는 일상</title>
  <link rel="icon" href="${ctx}/resources/favicon.ico" type="image/x-icon">
  <link rel="apple-touch-icon" href="${ctx}/resources/images/icon-180.png">
  <link rel="stylesheet" href="${ctx}/resources/css/shared.css">
  <link rel="stylesheet" href="${ctx}/resources/css/home.css">
</head>
<body class="page-home">
<a class="home-skip" href="#home-content">본문으로 건너뛰기</a>
<jsp:include page="includes/header.jsp" />
<main id="home-content" class="home-main">
  <section class="home-hero" aria-labelledby="home-title">
    <div class="home-intro">
      <p class="home-eyebrow">손으로 전하는 말, 마음을 잇는 배움</p>
      <h1 id="home-title">하루 한 단어,<br> <span>수어로 가까워져요.</span></h1>
      <p class="home-lead">모범 영상을 보고, 내 손으로 따라 하고.<br> 처음 배우는 수어도 SignBridge와 차근차근 시작하세요.</p>
      <div class="home-actions">
        <a class="home-primary" href="${ctx}/learn/signs">수어 학습 시작하기 <span aria-hidden="true">↗</span></a>
        <a class="home-secondary" href="${ctx}/learn/jamo">자음·모음부터 배우기</a>
      </div>
      <p class="home-note">웹캠 녹화와 평가는 로그인 후 이용할 수 있어요.</p>
    </div>
    <aside class="home-start" aria-labelledby="home-start-title">
      <div class="home-start-top"><span>처음이라면 여기부터</span><span aria-hidden="true">01</span></div>
      <h2 id="home-start-title">첫 만남과 나의 의사</h2>
      <p>‘나’와 ‘너’부터, 일상에서 나를 표현하는 단어를 만나보세요.</p>
      <div class="home-word-list" aria-label="학습 단어 예시"><span>나</span><span>너</span><span>반갑다</span></div>
      <a href="${ctx}/learn/signs">챕터별 단어 살펴보기 <span aria-hidden="true">→</span></a>
    </aside>
  </section>
  <section class="home-tools" aria-labelledby="home-tools-title">
    <div class="home-section-head"><div><p class="home-eyebrow">나에게 맞는 시작</p><h2 id="home-tools-title">배우고, 찾아보고, 함께 연습해요</h2></div><a href="${ctx}/learn">학습 홈 보기 →</a></div>
    <div class="home-tool-grid">
      <a class="home-tool" href="${ctx}/learn/dict"><span class="home-tool-symbol" aria-hidden="true">가</span><h3>수어 사전</h3><p>궁금한 단어를 검색하고<br> 영상으로 뜻과 동작을 확인해요.</p><span class="home-tool-link">단어 찾아보기 <span aria-hidden="true">→</span></span></a>
      <a class="home-tool" href="${ctx}/exam/setup"><span class="home-tool-symbol" aria-hidden="true">✓</span><h3>수어 시험</h3><p>배운 내용을 얼마나 기억하는지<br> 시험으로 확인해 보세요.</p><span class="home-tool-link">시험 준비하기 <span aria-hidden="true">→</span></span></a>
      <a class="home-tool" href="${ctx}/playzone/chain"><span class="home-tool-symbol" aria-hidden="true">↔</span><h3>수어 끝말잇기</h3><p>다른 사람들과 단어를 이어 가며<br> 즐겁게 수어를 연습해요.</p><span class="home-tool-link">플레이존 가기 <span aria-hidden="true">→</span></span></a>
      <a class="home-tool" href="${ctx}/board/list"><span class="home-tool-symbol" aria-hidden="true">“</span><h3>함께하는 게시판</h3><p>궁금한 점을 묻고<br> 나의 학습 경험을 나눠 보세요.</p><span class="home-tool-link">게시판 둘러보기 <span aria-hidden="true">→</span></span></a>
    </div>
  </section>
  <section class="home-guide" aria-labelledby="home-guide-title">
    <div><p class="home-eyebrow">웹캠 학습 이용 방법</p><h2 id="home-guide-title">보고, 따라 하고,<br> 한 번 더 연습해요.</h2></div>
    <ol class="home-steps">
      <li><span aria-hidden="true">01</span><div><h3>모범 영상 보기</h3><p>챕터에서 단어를 골라 손모양과 움직임을 살펴보세요.</p></div></li>
      <li><span aria-hidden="true">02</span><div><h3>내 동작 녹화하기</h3><p>로그인 후 카메라를 켜고, 손과 어깨가 보이도록 따라 해 보세요.</p></div></li>
      <li><span aria-hidden="true">03</span><div><h3>결과 확인하고 다시 연습하기</h3><p>녹화 후 단어 인식 결과와 제공 가능한 자세 피드백을 확인하세요.</p></div></li>
    </ol>
  </section>
</main>
<jsp:include page="includes/footer.jsp" />
</body>
</html>
