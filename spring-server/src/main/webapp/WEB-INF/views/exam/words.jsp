<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="_csrf" content="${_csrf.token}"><meta name="_csrf_header" content="${_csrf.headerName}">
  <title>수어 단어 시험 · SignBridge</title>
  <link rel="stylesheet" href="<c:url value='/resources/css/shared.css'/>">
  <link rel="stylesheet" href="<c:url value='/resources/css/word-exam.css'/>">
  <link rel="stylesheet" href="<c:url value='/resources/css/sign-coaching.css'/>">
</head>
<body>
<jsp:include page="../includes/header.jsp" />
<main id="word-exam" class="we-page" data-context="${pageContext.request.contextPath}">
  <div class="we-heading"><div><p class="we-eyebrow">배운 단어를 내 것으로</p><h1>수어 단어 시험</h1><p>영상을 이해하고, 직접 표현하며 학습한 내용을 확인해요.</p></div></div>
  <p id="we-status" role="status" aria-live="polite"></p>
  <section id="we-setup" class="we-panel">
    <h2>어디까지 익혔나요?</h2><p class="we-muted">기본 70단어 · 7개 챕터</p>
    <div class="we-fields"><label>출제 범위<select id="we-scope"><option value="">종합 · 챕터별 2문항, 총 14문항</option></select></label>
      <label>시험 방식<select id="we-mode"><option value="both">영상 이해 + 동작 표현</option><option value="choice">영상 이해</option><option value="motion">동작 표현</option></select></label></div>
    <div class="we-note"><strong>동작 표현은 AI 학습 평가예요.</strong><p>인식이 불확실하면 오답으로 단정하지 않고 다시 촬영해요. 자세 비교 점수는 정확도나 시험 합격 점수가 아니며, 포인트는 지급하지 않아요.</p></div>
    <button id="we-start" class="btn btn-primary" type="button" disabled>시험 시작</button>
    <h3 class="we-history-title">최근 시험</h3><div id="we-history" class="we-history"></div>
  </section>
  <section id="we-active" class="we-panel" hidden>
    <div class="we-question-head"><span id="we-progress" class="we-eyebrow"></span><span id="we-kind" class="badge badge-primary"></span></div>
    <progress id="we-bar" max="100" value="0" aria-label="시험 진행률"></progress>
    <h2 id="we-prompt"></h2>
    <div id="we-choice" hidden><video id="we-video" controls playsinline preload="metadata" aria-label="문제 수어 영상"></video><p id="we-video-error" class="we-muted" role="status"></p><div id="we-options" class="we-options"></div></div>
    <div id="we-motion" hidden>
      <p class="we-muted">앉은 자세에서 양쪽 어깨와 동작하는 손을 보여 주세요. 쉬는 손은 내려놓아도 돼요.</p>
      <div class="we-camera-grid"><div><video id="we-camera" autoplay muted playsinline aria-label="카메라 미리보기"></video><button id="we-camera-on" class="btn btn-ghost" type="button">카메라 켜기</button></div>
        <div id="we-preview-box" hidden><video id="we-preview" controls muted playsinline aria-label="제출할 녹화 영상"></video><p class="we-muted">동작 전체가 담겼는지 확인한 뒤 제출해 주세요.</p></div></div>
      <div class="we-actions"><button id="we-record" class="btn btn-primary" type="button" disabled>녹화 시작</button><button id="we-stop" class="btn btn-danger" type="button" disabled>녹화 종료</button><span id="we-timer" aria-live="off">00:00</span></div>
      <p id="we-attempt" class="we-muted" role="status"></p>
    </div>
    <div class="we-actions"><button id="we-submit" class="btn btn-primary" type="button" disabled>답안 제출</button><button id="we-skip" class="btn btn-ghost" type="button">이 문제는 나중에 연습할게요</button><button id="we-next" class="btn btn-primary" type="button" hidden>다음 문제</button></div>
  </section>
  <section id="we-result" class="we-panel" hidden><p class="we-eyebrow">다음 연습을 위한 기록</p><h2>시험 결과</h2><div id="we-summary" class="we-summary"></div><p class="we-muted">건너뛰었거나 인식하지 못한 문제는 복습이 필요해요. 동작 표현은 AI의 단어 인식 결과이며 수어의 모든 표현을 평가하지는 못해요.</p>
    <div class="we-actions"><button id="we-review" class="btn btn-primary" type="button">필요한 단어로 다시 도전하기</button><a class="btn btn-ghost" href="<c:url value='/exam/setup'/>">새 시험</a></div><div id="we-results"></div>
  </section>
  <noscript>시험을 이용하려면 JavaScript를 켜 주세요.</noscript>
</main>
<jsp:include page="../includes/footer.jsp" />
<script src="<c:url value='/resources/js/sign-coaching.js'/>?v=highlight-notes-2" defer></script>
<script src="<c:url value='/resources/js/word-exam.js'/>" defer></script>
</body></html>
