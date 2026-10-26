<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<meta name="_csrf" content="${_csrf.token}"/>
<meta name="_csrf_header" content="${_csrf.headerName}"/>
<link rel="stylesheet" href="${ctx}/resources/css/site-header.css">
<header class="sb-header">
  <a class="sb-brand" href="${ctx}/" aria-label="SignBridge 홈"><img src="${ctx}/resources/images/icon-180.png" alt="" width="32" height="32">SignBridge</a>
  <button class="sb-menu-toggle" type="button" aria-expanded="false" aria-controls="sb-navigation" hidden>메뉴</button>
  <nav id="sb-navigation" class="sb-navigation" aria-label="주요 메뉴">
    <a class="sb-link" data-section="home" href="${ctx}/">홈</a>
    <details class="sb-menu" data-section="learn">
      <summary>학습 <span aria-hidden="true">⌄</span></summary>
      <div class="sb-dropdown">
        <a href="${ctx}/learn">학습 홈 <small>나에게 맞는 학습 선택하기</small></a>
        <a href="${ctx}/learn/signs">챕터별 수어 학습 <small>모범 영상을 보고 웹캠으로 연습하기</small></a>
        <a href="${ctx}/learn/jamo">자음·모음 <small>기본 손모양부터 차근차근</small></a>
        <a href="${ctx}/learn/dict">수어 사전 <small>궁금한 단어 찾아보기</small></a>
      </div>
    </details>
    <a class="sb-link" data-section="exam" href="${ctx}/exam/setup">시험</a>
    <details class="sb-menu" data-section="playzone">
      <summary>플레이존 <span aria-hidden="true">⌄</span></summary>
      <div class="sb-dropdown">
        <a href="${ctx}/playzone/chain">수어 끝말잇기 <small>함께 즐기는 수어 단어 게임</small></a>
        <span class="sb-unavailable">수어 디펜스 <small>준비 중</small></span>
      </div>
    </details>
    <a class="sb-link" data-section="board" href="${ctx}/board/list">게시판</a>
    <div class="sb-account">
      <sec:authorize access="hasRole('ADMIN')"><a class="sb-link" href="${ctx}/admin/main">관리자</a></sec:authorize>
      <sec:authorize access="isAuthenticated()">
        <jsp:include page="../notification/notification.jsp" />
        <a class="sb-account-link" data-section="member" href="${ctx}/member/mypage">내 계정</a>
        <form action="${ctx}/member/logout" method="post">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
          <button class="sb-logout" type="submit">로그아웃</button>
        </form>
      </sec:authorize>
      <sec:authorize access="!isAuthenticated()">
        <a class="sb-link" href="${ctx}/member/login">로그인</a>
        <a class="sb-account-link" href="${ctx}/member/join">회원가입</a>
      </sec:authorize>
    </div>
  </nav>
</header>
<script src="${ctx}/resources/js/site-header.js" defer></script>
<sec:authorize access="isAuthenticated()">
  <script>window.ctx = "${ctx}";</script>
  <script src="${ctx}/resources/js/notification.js"></script>
</sec:authorize>
