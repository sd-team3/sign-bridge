<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="_csrf" content="${_csrf.token}">
<meta name="_csrf_header" content="${_csrf.headerName}">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - 마이페이지</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />
<main>
  <div class="mp-wrap">

    <!-- 프로필 히어로 -->
    <div class="mp-hero">
      <div class="mp-hero-ring">
        <svg viewBox="0 0 96 96">
          <circle class="track" cx="48" cy="48" r="44"></circle>
          <circle class="fill" cx="48" cy="48" r="44" stroke-dasharray="276" stroke-dashoffset="72"></circle>
        </svg>
        <div class="mp-hero-avatar">👤</div>
      </div>
      <div class="mp-hero-info">
        <div class="mp-hero-name-row">
          <span class="mp-hero-name">${member.memberName}</span>
          <!-- <span class="mp-hero-tier">🥇 골드 티어</span> -->
        </div>
        <div class="mp-hero-meta">${member.memberEmail}</div>
        <!-- <div class="mp-hero-pct">이번 달 학습 진행률 74%</div> -->
      </div>
      <button class="mp-hero-edit" onclick="mpTab('settings')">프로필 수정</button>
    </div>

    <!-- 요약 통계 -->
    <div class="mp-stats">
      <div class="mp-stat"><div class="mp-stat-num">${overviewStats.learnedWordCount}</div><div class="mp-stat-lbl">학습한 단어</div></div>
      <div class="mp-stat"><div class="mp-stat-num">${overviewStats.avgAccuracy}%</div><div class="mp-stat-lbl">평균 정확도</div></div>
      <div class="mp-stat"><div class="mp-stat-num">${overviewStats.streakDays}일</div><div class="mp-stat-lbl">연속 학습</div></div>
      <div class="mp-stat"><div class="mp-stat-num">${overviewStats.earnedBadges.size()} / 8</div><div class="mp-stat-lbl">획득 뱃지</div></div>
    </div>

    <!-- 탭 -->
    <div class="mp-tabs">
      <button class="mp-tab active" data-tab="overview" onclick="mpTab('overview')">학습 현황</button>
      <button class="mp-tab" data-tab="learninghistory" onclick="mpTab('learninghistory')">학습 기록</button>
      <button class="mp-tab" data-tab="wronganswer" onclick="mpTab('wronganswer')">오답노트</button>
      <button class="mp-tab" data-tab="badges" onclick="mpTab('badges')">뱃지</button>
      <button class="mp-tab" data-tab="mycontent" onclick="mpTab('mycontent')">작성물 관리</button>
      <button class="mp-tab" data-tab="settings" onclick="mpTab('settings')">계정 설정</button>
    </div>

    <!-- 학습 현황 -->
    <div class="mp-panel active" id="mp-panel-overview">
      <div class="mp-card">
        <div class="mp-card-title">초성별 진행률</div>
        <div class="mp-cho-progress-grid">
          <c:forEach var="p" items="${overviewStats.choseongProgress}">
            <div class="mp-progress-row">
              <div class="mp-progress-cat">${p.choseong}</div>
              <div class="mp-progress-track"><div class="mp-progress-fill" style="width:${p.percentage}%"></div></div>
              <div class="mp-progress-pct">${p.percentage}%</div>
            </div>
          </c:forEach>
        </div>
      </div>

      <div class="mp-card">
        <div class="mp-card-title">최근 학습 단어</div>
        <div class="mp-chip-row">
          <c:choose>
            <c:when test="${not empty overviewStats.recentWords}">
              <c:forEach var="word" items="${overviewStats.recentWords}">
                <span class="mp-chip">${word}</span>
              </c:forEach>
            </c:when>
            <c:otherwise>
              <span class="mp-list-empty">아직 학습한 단어가 없습니다.</span>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <div class="mp-card">
        <div class="mp-card-title">즐겨찾기한 수어</div>
        <div class="mp-list-wrap" id="fav-wrap"></div>
      </div>
      <div class="pagination" id="fav-pagination"></div>
    </div>

    <!-- 학습 기록 -->
    <div class="mp-panel" id="mp-panel-learninghistory">
      <div class="mp-subtabs">
        <button class="mp-subtab active" data-subtab="jamo" onclick="lhSubTab('jamo')">자모</button>
        <button class="mp-subtab" data-subtab="word" onclick="lhSubTab('word')">단어</button>
      </div>

      <!-- 자모 서브탭 -->
      <div class="mp-subpanel active" id="mp-subpanel-jamo">
        <div class="mp-card">
          <div class="mp-filter-row" data-scope="jamohistory">
            <button class="mp-filter-chip active" data-category="">전체</button>
            <button class="mp-filter-chip" data-category="CONSONANT">자음</button>
            <button class="mp-filter-chip" data-category="VOWEL">모음</button>
          </div>
          <div class="history-table-header"><div>단어</div><div>날짜</div><div>정확도</div></div>
          <div class="mp-list-wrap" id="jamo-history-wrap"></div>
        </div>
        <div class="pagination"></div>
      </div>

      <!-- 단어 서브탭 -->
      <div class="mp-subpanel" id="mp-subpanel-word">
        <div class="mp-card">
          <div class="history-table-header"><div>단어</div><div>날짜</div><div>결과</div></div>
          <div class="mp-list-wrap" id="word-history-wrap"></div>
        </div>
        <div class="pagination"></div>
      </div>
    </div>

    <!-- 오답노트 -->
    <div class="mp-panel" id="mp-panel-wronganswer">
      <div class="mp-wrongnote-summary">
        <span class="badge badge-danger" id="wa-total-badge">틀린 단어 0개</span>
      </div>
      <div class="mp-filter-row" data-scope="wronganswer">
        <button class="mp-filter-chip active" data-category="">전체</button>
        <button class="mp-filter-chip" data-category="CONSONANT">자음</button>
        <button class="mp-filter-chip" data-category="VOWEL">모음</button>
        <button class="mp-filter-chip" data-category="WORD">단어</button>
      </div>
      <div class="wrong-list-card">
        <h3>⚠️ 틀린 단어 모음</h3>
        <table class="wrong-table">
          <thead>
            <tr><th>#</th><th>단어</th><th>유형</th><th>내 답 → 정답</th><th>오답 날짜</th><th></th></tr>
          </thead>
          <tbody id="wrongnote-tbody"></tbody>
        </table>
      </div>
      <div class="pagination"></div>
    </div>

    <!-- 뱃지 -->
    <div class="mp-panel" id="mp-panel-badges">
      <div class="mp-card">
        <div class="mp-card-title">획득한 뱃지 ${overviewStats.earnedBadges.size()} / 8</div>
        <div class="mp-badge-grid">
          <div class="mp-badge-card ${fn:contains(overviewStats.earnedBadgesCsv, ',first_step,') ? '' : 'locked'}">
            <img class="mp-badge-icon" src="/resources/images/badges/first_step.png" alt="첫 걸음">
            <div class="mp-badge-name">첫 걸음</div><div class="mp-badge-desc">첫 수어 학습 완료</div>
          </div>
          <div class="mp-badge-card ${fn:contains(overviewStats.earnedBadgesCsv, ',streak7,') ? '' : 'locked'}">
            <img class="mp-badge-icon" src="/resources/images/badges/streak7.png" alt="7일 연속">
            <div class="mp-badge-name">7일 연속</div><div class="mp-badge-desc">7일 연속 학습 달성</div>
          </div>
          <div class="mp-badge-card locked">
            <img class="mp-badge-icon" src="/resources/images/badges/greeting_master.png" alt="인사 마스터">
            <div class="mp-badge-name">인사 마스터</div><div class="mp-badge-desc">인사 카테고리 완료</div>
          </div>
          <div class="mp-badge-card locked">
            <img class="mp-badge-icon" src="/resources/images/badges/food_master.png" alt="음식 마스터">
            <div class="mp-badge-name">음식 마스터</div><div class="mp-badge-desc">음식 카테고리 완료</div>
          </div>
          <div class="mp-badge-card ${fn:contains(overviewStats.earnedBadgesCsv, ',word_master,') ? '' : 'locked'}">
            <img class="mp-badge-icon" src="/resources/images/badges/word_master.png" alt="수어 고수">
            <div class="mp-badge-name">수어 고수</div><div class="mp-badge-desc">50개 이상 완료</div>
          </div>
          <div class="mp-badge-card locked">
            <img class="mp-badge-icon" src="/resources/images/badges/complete_all.png" alt="완전 정복">
            <div class="mp-badge-name">완전 정복</div><div class="mp-badge-desc">모든 카테고리 완료</div>
          </div>
          <div class="mp-badge-card ${fn:contains(overviewStats.earnedBadgesCsv, ',streak30,') ? '' : 'locked'}">
            <img class="mp-badge-icon" src="/resources/images/badges/streak30.png" alt="30일 연속">
            <div class="mp-badge-name">30일 연속</div><div class="mp-badge-desc">30일 연속 학습</div>
          </div>
          <div class="mp-badge-card locked">
            <img class="mp-badge-icon" src="/resources/images/badges/allstar.png" alt="올스타">
            <div class="mp-badge-name">올스타</div><div class="mp-badge-desc">모든 뱃지 획득</div>
          </div>
        </div>
      </div>
    </div>
    
<!-- 작성물 관리 -->
<div class="mp-panel" id="mp-panel-mycontent">
  <div class="mp-subtabs">
    <button class="mp-subtab active" data-subtab="myposts" onclick="mcSubTab('myposts')">게시글 관리</button>
    <button class="mp-subtab" data-subtab="mycomments" onclick="mcSubTab('mycomments')">댓글 관리</button>
  </div>

    <!-- 게시글 서브탭 -->
    <div class="mp-subpanel active" id="mp-subpanel-myposts">
      <div class="mp-card">
        <div class="mp-filter-row" data-scope="myposts">
          <button class="mp-filter-chip active" data-category="">전체</button>
          <button class="mp-filter-chip" data-category="FREE">자유</button>
          <button class="mp-filter-chip" data-category="QNA">질문</button>
          <button class="mp-filter-chip" data-category="INFO">정보</button>
          <button class="mp-filter-chip" data-category="REPORT">신고</button>
          <button class="mp-filter-chip" data-category="NOTICE">공지</button>
        </div>
        <div class="mp-post-table-head"><div>제목</div><div>카테고리</div><div>댓글</div><div>작성일</div></div>
        <div class="mp-list-wrap"></div>
      </div>
      <div class="pagination"></div>
    </div>

    <!-- 댓글 서브탭 -->
    <div class="mp-subpanel" id="mp-subpanel-mycomments">
      <div class="mp-card">
        <div class="mp-filter-row" data-scope="mycomments">
          <button class="mp-filter-chip active" data-category="">전체</button>
          <button class="mp-filter-chip" data-category="FREE">자유</button>
          <button class="mp-filter-chip" data-category="QNA">질문</button>
          <button class="mp-filter-chip" data-category="INFO">정보</button>
          <button class="mp-filter-chip" data-category="REPORT">신고</button>
          <button class="mp-filter-chip" data-category="NOTICE">공지</button>
        </div>
        <div class="mp-comment-table-head"><div>내용</div><div>답글</div><div>게시글</div></div>
        <div class="mp-list-wrap"></div>
      </div>
      <div class="pagination"></div>
    </div>
  </div>

    <!-- 계정 설정 -->
    <div class="mp-panel" id="mp-panel-settings">
      <div class="mp-card">
        <form id="basicInfoForm">
          <input type="hidden" name="memberId" value="${member.memberId}">
          <div class="mp-card-title">기본 정보</div>
          <div class="form-group">
            <label class="form-label" for="name">이름</label>
            <input type="text" id="name" class="form-input" value="${member.memberName}">
          </div>
          <div class="form-group">
            <label class="form-label" for="email">이메일</label>
            <input type="email" id="email" class="form-input" value="${member.memberEmail}" readonly>
          </div>
          <button type="submit" class="btn btn-primary">변경 사항 저장</button>
        </form>
      </div>

      <c:choose>
        <c:when test="${member.provider == 'LOCAL'}">
          <div class="mp-card">
            <form id="passwordForm">
              <div class="mp-card-title">비밀번호 변경</div>
              <div class="form-group">
                <label class="form-label" for="pw-current">현재 비밀번호</label>
                <input type="password" id="pw-current" class="form-input" placeholder="현재 비밀번호">
              </div>
              <div class="form-group">
                <label class="form-label" for="pw-new">새 비밀번호</label>
                <input type="password" id="pw-new" class="form-input" placeholder="새 비밀번호 (8자 이상)">
              </div>
              <div class="form-group">
                <label class="form-label" for="pw-confirm">새 비밀번호 확인</label>
                <input type="password" id="pw-confirm" class="form-input" placeholder="새 비밀번호 재입력">
              </div>
              <button type="submit" class="btn btn-primary">비밀번호 변경</button>
            </form>
          </div>
        </c:when>
        <c:otherwise>
          <div class="mp-card">
            <div class="mp-card-title">로그인 방식</div>
            <p class="mp-danger-text" style="color:var(--text-sub);">
              <c:choose>
                <c:when test="${member.provider == 'GOOGLE'}">Google</c:when>
                <c:when test="${member.provider == 'NAVER'}">네이버</c:when>
                <c:when test="${member.provider == 'KAKAO'}">카카오</c:when>
                <c:otherwise>${member.provider}</c:otherwise>
              </c:choose>
              계정으로 로그인되어 있어 비밀번호를 별도로 관리하지 않습니다.
            </p>
          </div>
        </c:otherwise>
      </c:choose>

      <div class="mp-card">
        <div class="mp-card-title">알림</div>
        <div class="mp-toggle-row">
          <div class="mp-toggle-key">게시판 댓글 알림<span>내 글에 댓글이 달리면 알려드려요.</span></div>
          <div class="mp-toggle on" id="toggle-notif-comment" onclick="this.classList.toggle('on')"></div>
        </div>
        <div class="mp-toggle-row">
          <div class="mp-toggle-key">Q&amp;A 처리 결과 알림<span>오류 신고나 단어 건의가 처리되면 알려드려요.</span></div>
          <div class="mp-toggle on" id="toggle-notif-qna" onclick="this.classList.toggle('on')"></div>
        </div>
      </div>

      <div class="mp-card">
        <div class="mp-card-title">화면 설정</div>

        <div class="mp-choice-label">테마</div>
        <div class="mp-choice-row" data-group="theme">
          <div class="mp-choice" data-value="light"><span class="mp-choice-icon">☀️</span>라이트</div>
          <div class="mp-choice" data-value="dark"><span class="mp-choice-icon">🌙</span>다크</div>
          <div class="mp-choice" data-value="system"><span class="mp-choice-icon">🖥️</span>시스템 설정</div>
        </div>

        <div class="mp-choice-label">글자 크기</div>
        <div class="mp-choice-row" data-group="fontsize">
          <div class="mp-choice" data-value="small">Aa<span style="display:block; font-size:11px; font-weight:600; margin-top:4px;">작게</span></div>
          <div class="mp-choice" data-value="normal">Aa<span style="display:block; font-size:11px; font-weight:600; margin-top:4px;">보통</span></div>
          <div class="mp-choice" data-value="large">Aa<span style="display:block; font-size:11px; font-weight:600; margin-top:4px;">크게</span></div>
        </div>
      </div>

      <div class="mp-card">
        <div class="mp-card-title">로그아웃</div>
        <p class="mp-danger-text" style="color:var(--text-sub);">현재 계정에서 로그아웃합니다.</p>
        <form action="/member/logout" method="post">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
          <button type="submit" class="btn btn-ghost btn-sm">로그아웃</button>
        </form>
      </div>

      <div class="mp-card mp-danger-card">
          <div class="mp-card-title">계정 삭제</div>
          <p class="mp-danger-text">계정을 삭제하면 학습 기록, 게시글 등 모든 데이터가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.</p>
          <c:if test="${member.provider == 'LOCAL'}">
            <input type="password" id="withdraw-password" class="form-input" placeholder="비밀번호 확인" style="margin-bottom:10px;">
          </c:if>
          <button id="deleteBtn" class="btn btn-danger btn-sm">계정 영구 삭제</button>
      </div>
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

<script src="/resources/js/mypage.js"></script>

</body>
</html>
