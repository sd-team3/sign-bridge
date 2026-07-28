<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<header>
    <div class="logo">✋ SignBridge</div>
    <nav>
    <a href="${ctx}/">홈</a>
    <div class="nav-item has-sub">
        <a href="${ctx}/learn">학습 <span class="nav-caret">▾</span></a>
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
                <span class="nav-dropdown-title">수어사전</span>
                <span class="nav-dropdown-desc">초성으로 찾고 검색해서 단어 학습</span>
            </span>
            </a>
        </div>
        </div>
    </div>
    <a href="${ctx}/exam/setup">시험</a>
    <div class="nav-item has-sub">
        <a href="#">플레이존 <span class="nav-caret">▾</span></a>
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
    <a href="#">게시판</a>
    <sec:authorize access="isAuthenticated()">
        <a href="${ctx}/member/mypage" class="active btn btn-ghost btn-sm" style="margin-left:12px;">내 계정</a>
    </sec:authorize>

    <sec:authorize access="!isAuthenticated()">
        <a href="${ctx}/member/login" class="active btn btn-ghost btn-sm" style="margin-left:12px;">로그인</a>
    </sec:authorize>
    </nav>
</header>