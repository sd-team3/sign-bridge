<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="_csrf" content="${_csrf.token}">
  <meta name="_csrf_header" content="${_csrf.headerName}">
  <title>챕터별 수어 학습 · SignBridge</title>
  <link rel="stylesheet" href="<c:url value='/resources/css/shared.css'/>">
  <link rel="stylesheet" href="<c:url value='/resources/css/sign-learning.css'/>">
</head>
<body>
<jsp:include page="../includes/header.jsp" />
<c:set var="signedIn" value="false" />
<sec:authorize access="isAuthenticated()"><c:set var="signedIn" value="true" /></sec:authorize>
<main id="sign-learning" class="sl-page" data-context="${pageContext.request.contextPath}" data-signed-in="${signedIn}">
  <div class="sl-intro">
    <div><a class="sl-back" href="<c:url value='/learn'/>">← 학습 홈</a>
      <p class="sl-eyebrow">하나씩 보고, 직접 따라 해요</p>
      <h1>챕터별 수어 학습</h1>
      <p>단어를 골라 모범 동작을 보고, 웹캠으로 따라 하며 피드백을 받아보세요.</p>
    </div>
    <span id="sl-course-count" class="badge badge-primary">과정 불러오는 중</span>
  </div>
  <div id="sl-catalog-error" class="sl-alert" role="alert" hidden>
    <p id="sl-catalog-message"></p><button id="sl-reload" class="btn btn-ghost" type="button">다시 불러오기</button>
  </div>
  <div class="sl-layout">
    <aside class="sl-catalog" aria-label="챕터와 단어 목록">
      <div class="sl-catalog-heading"><h2>학습 단어</h2><span>챕터를 펼쳐 선택하세요</span></div>
      <div id="sl-chapters" aria-busy="true"><p class="sl-placeholder">챕터를 불러오고 있어요…</p></div>
    </aside>
    <section class="sl-practice" aria-label="단어 연습">
      <div id="sl-empty" class="sl-empty"><span aria-hidden="true">🤟</span><h2>오늘의 첫 단어를 골라보세요</h2><p>왼쪽 목록에서 단어를 선택하면 연습을 시작할 수 있어요.</p></div>
      <div id="sl-workspace" hidden>
        <div class="sl-word-heading"><div><p id="sl-chapter-label" class="sl-eyebrow"></p><h2 id="sl-word-label"></h2></div><span id="sl-word-order" class="badge badge-primary"></span></div>
        <div class="sl-videos">
          <section class="sl-video-card">
            <h3>1. 모범 동작 보기</h3>
            <div class="sl-video-wrap"><video id="sl-reference" controls loop playsinline preload="auto" aria-label="모범 수어 영상"></video></div>
            <div class="sl-video-tools"><button id="sl-restart" type="button" class="btn btn-ghost btn-sm">처음부터</button>
              <label>재생 속도 <select id="sl-speed"><option value="0.5">0.5배</option><option value="0.75">0.75배</option><option value="1" selected>1배</option></select></label>
            </div>
            <p id="sl-reference-status" class="sl-hint" role="status">모범 영상을 준비하고 있어요.</p>
          </section>
          <section class="sl-video-card">
            <h3>2. 웹캠으로 따라 하기 <span id="sl-timer">00:00</span></h3>
            <div class="sl-video-wrap sl-camera-wrap"><video id="sl-camera" autoplay playsinline muted aria-label="내 카메라 미리보기"></video><p id="sl-camera-placeholder">카메라를 켜고 동작을 따라 해보세요.</p><span id="sl-recording-badge" hidden>● 녹화 중</span></div>
            <div class="sl-video-tools"><button id="sl-start-camera" type="button" class="btn btn-ghost btn-sm">카메라 켜기</button><button id="sl-stop-camera" type="button" class="btn btn-ghost btn-sm" disabled>카메라 끄기</button></div>
            <p class="sl-hint">미리보기는 거울처럼 보입니다. 음성은 녹음하지 않아요.</p>
          </section>
        </div>
        <p id="sl-guidance" class="sl-guidance">양쪽 어깨와 동작에 사용하는 손이 보이도록 촬영해 주세요.</p>
        <div id="sl-login-notice" class="sl-alert" <c:if test="${signedIn}">hidden</c:if>>모범 영상은 바로 볼 수 있어요. 웹캠 피드백은 <a href="<c:url value='/member/login'/>">로그인</a> 후 이용해 주세요.</div>
        <div class="sl-actions"><button id="sl-record" type="button" class="btn btn-primary" disabled>녹화 시작</button><button id="sl-finish" type="button" class="btn btn-danger" disabled>종료 후 평가</button><button id="sl-resubmit" type="button" class="btn btn-ghost" hidden>같은 영상 다시 평가</button></div>
        <p id="sl-status" class="sl-status" role="status" aria-live="polite">2~10초 동안 동작 전체를 촬영해 주세요. 최대 19초에 자동 종료됩니다.</p>
        <section id="sl-result" class="sl-result" aria-live="polite" hidden>
          <p class="sl-eyebrow">이번 연습 결과</p><h3 id="sl-recognition"></h3><p id="sl-prediction"></p>
          <div class="sl-feedback"><h4>자세 피드백</h4><p id="sl-feedback-message"></p></div>
          <p class="sl-hint">단어 인식과 자세 피드백은 별개예요. 학습 완료나 자세 정확도 점수를 의미하지 않습니다.</p>
        </section>
        <div class="sl-word-nav"><button id="sl-prev" type="button" class="btn btn-ghost">← 이전 단어</button><span id="sl-session-note">결과는 현재 페이지에서 확인할 수 있어요.</span><button id="sl-next" type="button" class="btn btn-ghost">다음 단어 →</button></div>
      </div>
    </section>
  </div>
  <noscript><p class="sl-alert">단어 목록과 웹캠 피드백을 이용하려면 JavaScript를 켜 주세요.</p></noscript>
</main>
<jsp:include page="../includes/footer.jsp" />
<script src="<c:url value='/resources/js/sign-learning.js'/>" defer></script>
</body>
</html>
