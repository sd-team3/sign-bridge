<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>

<!-- 사이드바 -->
<div class="board-sidebar">
    <div class="sidebar-box">
        <div class="sidebar-box-header">글쓰기</div>
        <div class="sidebar-write-btns">
        <a href="/board/write" class="btn btn-primary btn-sm">✏️ 일반 글쓰기</a>
        <a href="/board/write?category=REPORT" class="btn btn-ghost btn-sm">⚠️ 오류 신고</a>
    </div>
</div>
    <div class="sidebar-box">
        <div class="sidebar-box-header">게시판 현황</div>
        <div class="sidebar-stats">
            <div class="stat-row"><span class="lbl">전체 게시글</span><span class="val">${allBoardCnt}</span></div>
            <div class="stat-row"><span class="lbl">공지</span><span class="val">${noticeBoardCnt}</span></div>
            <div class="stat-row"><span class="lbl">자유</span><span class="val">${freeBoardCnt}</span></div>
            <div class="stat-row"><span class="lbl">질문</span><span class="val">${qnaBoardCnt}</span></div>
            <div class="stat-row"><span class="lbl">정보</span><span class="val">${infoBoardCnt}</span></div>
            <div class="stat-row"><span class="lbl">오류신고</span><span class="val">${reportBoardCnt}</span></div>
        </div>
    </div>
</div>