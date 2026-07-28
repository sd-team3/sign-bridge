<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>

<header>
    <div class="logo">✋ SignBridge</div>
    <nav>
    <a href="/">홈</a>
    <div class="nav-item has-sub">
        <a href="/learn">학습 <span class="nav-caret">▾</span></a>
        <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
            <a href="/learn/jamo" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🤟</span>
            <span class="nav-dropdown-text">
                <span class="nav-dropdown-title">자/모음 지문자</span>
                <!-- <span class="nav-dropdown-desc">일상 속 기본 단어부터 차근차근</span> -->
            </span>
            </a>
            <!-- <a href="learn_list.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🚨</span>
            <span class="nav-dropdown-text">
                <span class="nav-dropdown-title">상황별 수어 학습</span>
                <span class="nav-dropdown-desc">지진, 화재 등 긴급 상황 어휘</span>
            </span>
            </a> -->
            <a href="/learn/dict" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔍</span>
            <span class="nav-dropdown-text">
                <span class="nav-dropdown-title">개별 어휘 학습</span>
                <!-- <span class="nav-dropdown-desc">분야별로 찾거나 검색해서 학습</span> -->
            </span>
            </a>
        </div>
        </div>
    </div>
    <a href="/exam/setup">시험</a>
    <div class="nav-item has-sub">
        <a href="play_chain.html">플레이존 <span class="nav-caret">▾</span></a>
        <div class="nav-dropdown">
        <div class="nav-dropdown-inner">
            <a href="play_chain.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🔗</span>
            <span class="nav-dropdown-text">
                <span class="nav-dropdown-title">수어 끝말잇기</span>
                <span class="nav-dropdown-desc">AI와 실시간 끝말잇기 대결</span>
            </span>
            </a>
            <a href="play_defense.html" class="nav-dropdown-link">
            <span class="nav-dropdown-icon">🎯</span>
            <span class="nav-dropdown-text">
                <span class="nav-dropdown-title">수어 디펜스</span>
                <span class="nav-dropdown-desc">떨어지는 단어를 수어로 막기</span>
            </span>
            </a>
        </div>
        </div>
    </div>
    <a href="board_list.html">게시판</a>
    <sec:authorize access="isAuthenticated()">
        <a href="/member/mypage" class="active btn btn-ghost btn-sm" style="margin-left:12px;">내 계정</a>
    </sec:authorize>

    <sec:authorize access="!isAuthenticated()">
        <a href="/member/login" class="active btn btn-ghost btn-sm" style="margin-left:12px;">로그인</a>
    </sec:authorize>
    </nav>
</header>