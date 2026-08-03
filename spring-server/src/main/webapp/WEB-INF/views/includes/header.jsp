<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<nav>
  <a href="${ctx}/" class="nav-logo">
    <div class="nav-logo-icon">✋</div>
    <span class="nav-logo-text">SignBridge</span>
  </a>

  <div class="nav-links">
    <div class="nav-item has-sub">
      <a href="${ctx}/learn" class="nav-link">학습<span class="nav-caret">▾</span></a>
      <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
          <a href="${ctx}/learn/jamo" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔤</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">자음,모음</span>
              <span class="nav-dropdown-desc">ㄱ부터 ㅎ까지, 자음과 모음 손모양 익히기</span>
            </span>
          </a>
          <a href="${ctx}/learn/dict" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔍</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">수어 사전</span>
              <span class="nav-dropdown-desc">초성으로 찾고 검색해서 단어 학습</span>
            </span>
          </a>
        </div>
      </div>
    </div>

    <a href="${ctx}/exam/setup" class="nav-link">시험</a>

    <div class="nav-item has-sub">
      <a href="#" class="nav-link">플레이존 <span class="nav-caret">▾</span></a>
      <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
          <a href="#" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔗</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">수어 끝말잇기</span>
              <span class="nav-dropdown-desc">AI와 실시간 끝말잇기 대결</span>
            </span>
          </a>
          <a href="#" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🎯</span>
            <span class="nav-dropdown-text">
              <span class="nav-dropdown-title">수어 디펜스</span>
              <span class="nav-dropdown-desc">떨어지는 단어를 수어로 막기</span>
            </span>
          </a>
        </div>
      </div>
    </div>

    <a href="#" class="nav-link">게시판</a>
  </div>

  <div class="nav-cta">
    <sec:authorize access="isAnonymous()">
      <div class="nav-cta-guest">
        <a href="${ctx}/member/login" class="btn btn-ghost">로그인</a>
        <a href="${ctx}/member/join" class="btn btn-primary">회원가입</a>
      </div>
    </sec:authorize>

    <sec:authorize access="isAuthenticated()">
      <jsp:include page="/WEB-INF/views/notification/notification.jsp" />

      <form action="${ctx}/member/logout" method="post" style="display:inline; margin-left:12px;">
        <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
        <button type="submit" class="btn btn-ghost btn-sm">로그아웃</button>
      </form>
      <a href="${ctx}/member/info" class="active btn btn-primary btn-sm" style="margin-left:8px;">내 계정</a>
    </sec:authorize>
  </div>
</nav>

<sec:authorize access="isAuthenticated()">
<script>
    window.ctx = "${ctx}";
</script>
<script src="${ctx}/resources/js/notification.js"></script>
</sec:authorize>