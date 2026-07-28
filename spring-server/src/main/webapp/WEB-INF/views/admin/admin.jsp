<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge 관리자</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/resources/css/admin.css">
</head>
<body>

<jsp:include page="sidebar.jsp" />

<!-- ═══════════ MAIN ═══════════ -->
<div class="main">

  <!-- TOPBAR -->
  <div class="topbar">
    <div style="display:flex;align-items:center;gap:12px">
      <button onclick="document.getElementById('sidebar').classList.toggle('open')" style="display:none;background:none;border:none;font-size:20px;cursor:pointer" id="menu-toggle">☰</button>
      <span class="topbar-title" id="topbar-title">대시보드</span>
    </div>
    <span class="topbar-path" id="topbar-path">/admin</span>
    <div class="topbar-right">
      <button class="topbar-btn btn-ghost" onclick="showToast('새로고침 되었습니다', '#2d9b6f')">↻ 새로고침</button>
      <a href="index.html" class="topbar-btn btn-ghost">← 사이트로</a>
    </div>
  </div>

  <!-- ══════════ PAGE: DASHBOARD ══════════ -->
  <div class="content page active" id="page-dashboard">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">개요</div>
        <div class="section-hd">대시보드</div>
        <div class="section-sub">오늘 2025년 6월 29일 기준 현황</div>
      </div>
    </div>

    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background:var(--p-light)">👥</div>
        <div class="stat-body">
          <div class="stat-label">전체 유저</div>
          <div class="stat-value">1,284</div>
          <div class="stat-delta delta-up">▲ +23 오늘</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background:var(--blue-light)">💬</div>
        <div class="stat-body">
          <div class="stat-label">전체 게시글</div>
          <div class="stat-value">3,810</div>
          <div class="stat-delta delta-up">▲ +41 오늘</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background:var(--rose-light)">🚨</div>
        <div class="stat-body">
          <div class="stat-label">오류 신고 (미처리)</div>
          <div class="stat-value">4</div>
          <div class="stat-delta delta-down">▼ 처리 필요</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background:var(--amber-light)">📝</div>
        <div class="stat-body">
          <div class="stat-label">단어 요청 (미처리)</div>
          <div class="stat-value">9</div>
          <div class="stat-delta delta-down">▼ 검토 필요</div>
        </div>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px">
      <!-- 주간 가입자 -->
      <div class="card">
        <div class="card-title"><span class="ct-icon">📈</span> 주간 신규 가입자</div>
        <div class="mini-chart" id="mini-chart"></div>
        <div style="display:flex;justify-content:space-between;margin-top:6px">
          <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">월</span>
          <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">화</span>
          <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">수</span>
          <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">목</span>
          <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">금</span>
          <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">토</span>
          <span style="font-size:11px;color:var(--ink3);font-family:'DM Mono',monospace">일</span>
        </div>
      </div>

      <!-- 최근 활동 -->
      <div class="card">
        <div class="card-title"><span class="ct-icon">⚡</span> 최근 활동</div>
        <div class="feed">
          <div class="feed-item">
            <div class="feed-dot" style="background:var(--rose)"></div>
            <div class="feed-text"><b>user_0923</b>이 오류 신고를 접수했습니다 — "화재" 단어 인식 오류</div>
            <span class="feed-time">5분 전</span>
          </div>
          <div class="feed-item">
            <div class="feed-dot" style="background:var(--p)"></div>
            <div class="feed-text">신규 회원 <b>이민준</b> 가입</div>
            <span class="feed-time">12분 전</span>
          </div>
          <div class="feed-item">
            <div class="feed-dot" style="background:var(--amber)"></div>
            <div class="feed-text"><b>김지수</b>가 단어 추가 요청 — "배달"</div>
            <span class="feed-time">34분 전</span>
          </div>
          <div class="feed-item">
            <div class="feed-dot" style="background:var(--purple)"></div>
            <div class="feed-text">게시글 #1042 신고 접수됨</div>
            <span class="feed-time">1시간 전</span>
          </div>
          <div class="feed-item">
            <div class="feed-dot" style="background:var(--p)"></div>
            <div class="feed-text"><b>admin</b>이 단어 "감사합니다" 수정</div>
            <span class="feed-time">2시간 전</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 빠른 접근 -->
    <div class="card">
      <div class="card-title"><span class="ct-icon">⚡</span> 빠른 작업</div>
      <div style="display:flex;gap:10px;flex-wrap:wrap">
        <button class="topbar-btn btn-primary" onclick="navigate(document.querySelector('[data-page=word-add]'))">➕ 단어 추가</button>
        <button class="topbar-btn btn-ghost" onclick="navigate(document.querySelector('[data-page=question-error]'))">🚨 오류 신고 확인 <span style="background:var(--rose);color:#fff;border-radius:10px;padding:1px 6px;font-size:10px;margin-left:2px">4</span></button>
        <button class="topbar-btn btn-ghost" onclick="navigate(document.querySelector('[data-page=question-add]'))">📝 단어 요청 확인 <span style="background:var(--amber);color:#fff;border-radius:10px;padding:1px 6px;font-size:10px;margin-left:2px">9</span></button>
        <button class="topbar-btn btn-ghost" onclick="navigate(document.querySelector('[data-page=user-list]'))">👥 유저 목록</button>
      </div>
    </div>
  </div>

  <!-- ══════════ PAGE: USER LIST ══════════ -->
  <div class="content page" id="page-user-list">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">사용자 관리</div>
        <div class="section-hd">유저 목록</div>
        <div class="section-sub">role 파라미터로 필터링 가능 <span class="topbar-path" style="font-size:11px">/admin/user/list?role=</span></div>
      </div>
    </div>

    <div class="filter-bar">
      <div class="search-wrap">
        <span class="si">🔍</span>
        <input type="text" placeholder="이름, 이메일, UID 검색...">
      </div>
      <select class="filter-select" id="role-filter" onchange="filterUsers()">
        <option value="">전체 역할</option>
        <option value="user">일반 유저</option>
        <option value="deaf">청각장애인</option>
        <option value="suspended">정지됨</option>
        <option value="admin">관리자</option>
      </select>
      <select class="filter-select">
        <option>가입일 최신순</option>
        <option>가입일 오래된순</option>
        <option>이름순</option>
      </select>
    </div>

    <div class="table-wrap">
      <table id="user-table">
        <thead>
          <tr>
            <th>UID</th>
            <th>이름</th>
            <th>이메일</th>
            <th>역할</th>
            <th>가입일</th>
            <th>최근 접속</th>
            <th>상태</th>
            <th>작업</th>
          </tr>
        </thead>
        <tbody id="user-tbody"></tbody>
      </table>
    </div>
    <div class="pagination">
      <button class="pg-btn">‹</button>
      <button class="pg-btn active">1</button>
      <button class="pg-btn">2</button>
      <button class="pg-btn">3</button>
      <button class="pg-btn">›</button>
    </div>
  </div>

  <!-- ══════════ PAGE: USER INFO ══════════ -->
  <div class="content page" id="page-user-info">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">사용자 관리</div>
        <div class="section-hd">유저 상세</div>
        <div class="section-sub">유저 목록에서 선택하거나 UID를 직접 조회</div>
      </div>
      <div style="display:flex;gap:8px">
        <button class="topbar-btn btn-warning" onclick="openModal('modal-stop')">⏸ 정지</button>
        <button class="topbar-btn btn-danger" onclick="openModal('modal-delete')">🗑 강퇴</button>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:280px 1fr;gap:16px;align-items:start">
      <!-- 프로필 카드 -->
      <div class="card" style="text-align:center">
        <div style="width:72px;height:72px;border-radius:50%;background:var(--p);display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:700;color:#fff;margin:0 auto 14px">김</div>
        <div style="font-size:17px;font-weight:800;color:var(--ink);margin-bottom:4px">김지수</div>
        <div style="font-size:13px;color:var(--ink3);margin-bottom:12px">jisu.kim@email.com</div>
        <span class="pill pill-green" style="margin-bottom:16px">일반 유저</span>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:12px;text-align:left">
          <div class="detail-row">
            <span class="detail-label">학습 수</span>
            <span class="detail-value mono">142</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">정확도</span>
            <span class="detail-value mono">91.4%</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">티어</span>
            <span class="detail-value">🥇 골드</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">XP</span>
            <span class="detail-value mono">3,280</span>
          </div>
        </div>
      </div>

      <!-- 상세 정보 -->
      <div style="display:flex;flex-direction:column;gap:16px">
        <div class="card">
          <div class="card-title"><span class="ct-icon">📋</span> 계정 정보</div>
          <div class="detail-grid">
            <div class="detail-row"><span class="detail-label">UID</span><span class="detail-value mono">USR-00284</span></div>
            <div class="detail-row"><span class="detail-label">가입일</span><span class="detail-value mono">2025-04-11</span></div>
            <div class="detail-row"><span class="detail-label">최근 접속</span><span class="detail-value mono">2025-06-29 09:14</span></div>
            <div class="detail-row"><span class="detail-label">가입 방법</span><span class="detail-value">일반 가입</span></div>
            <div class="detail-row"><span class="detail-label">청각장애인 여부</span><span class="detail-value">미선택</span></div>
            <div class="detail-row"><span class="detail-label">계정 상태</span><span class="pill pill-green">활성</span></div>
          </div>
        </div>
        <div class="card">
          <div class="card-title"><span class="ct-icon">📝</span> 최근 게시글</div>
          <div class="table-wrap">
            <table>
              <thead><tr><th>번호</th><th>제목</th><th>카테고리</th><th>작성일</th></tr></thead>
              <tbody>
                <tr><td class="td-mono">#1041</td><td>수어 인식이 자꾸 틀려요, 어떻게 하면 좋을까요?</td><td><span class="pill pill-blue">질문</span></td><td class="td-mono">2025-06-28</td></tr>
                <tr><td class="td-mono">#0987</td><td>SignBridge 덕분에 수어 실력이 늘었어요!</td><td><span class="pill pill-gray">일반</span></td><td class="td-mono">2025-06-20</td></tr>
                <tr><td class="td-mono">#0912</td><td>처음 가입했는데 어떻게 사용하나요?</td><td><span class="pill pill-gray">일반</span></td><td class="td-mono">2025-06-12</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ PAGE: WORD ADD ══════════ -->
  <div class="content page" id="page-word-add">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">단어 관리</div>
        <div class="section-hd">단어 추가</div>
        <div class="section-sub">새 수어 단어를 데이터베이스에 등록합니다</div>
      </div>
    </div>
    <div class="card">
      <div class="form-grid">
        <div class="form-row">
          <label class="fl">단어 (한글)</label>
          <input class="fi" type="text" placeholder="예: 안녕하세요">
        </div>
        <div class="form-row">
          <label class="fl">카테고리</label>
          <select class="fi">
            <option>기초 어휘</option>
            <option>비상 상황</option>
            <option>의료 · 건강</option>
            <option>교통 · 이동</option>
            <option>직장 · 공공기관</option>
            <option>가족 · 관계</option>
          </select>
        </div>
        <div class="form-row">
          <label class="fl">난이도</label>
          <select class="fi">
            <option>초급</option>
            <option>중급</option>
            <option>고급</option>
          </select>
        </div>
        <div class="form-row">
          <label class="fl">중요도 태그</label>
          <select class="fi">
            <option>일반</option>
            <option>필수</option>
            <option>비상</option>
          </select>
        </div>
        <div class="form-row full">
          <label class="fl">동영상 URL</label>
          <input class="fi" type="text" placeholder="https://cdn.signbridge.kr/videos/...">
        </div>
        <div class="form-row full">
          <label class="fl">설명 / 메모</label>
          <textarea class="fi" placeholder="이 단어에 대한 추가 설명이나 관리자 메모"></textarea>
        </div>
        <div class="form-actions">
          <button class="topbar-btn btn-primary" onclick="showToast('단어가 추가되었습니다 ✓', '#2d9b6f')">➕ 단어 추가</button>
          <button class="topbar-btn btn-ghost">초기화</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ PAGE: WORD UPDATE ══════════ -->
  <div class="content page" id="page-word-update">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">단어 관리</div>
        <div class="section-hd">단어 수정</div>
        <div class="section-sub">기존 단어 정보를 수정합니다</div>
      </div>
    </div>
    <div class="card" style="margin-bottom:16px">
      <div class="card-title"><span class="ct-icon">🔍</span> 단어 검색</div>
      <div class="filter-bar" style="margin-bottom:0">
        <div class="search-wrap">
          <span class="si">🔍</span>
          <input type="text" placeholder="수정할 단어 검색..." id="word-search-input">
        </div>
        <select class="filter-select">
          <option>전체 카테고리</option>
          <option>기초 어휘</option>
          <option>비상 상황</option>
        </select>
        <button class="topbar-btn btn-primary" onclick="showToast('단어를 검색했습니다', '#2d9b6f')">검색</button>
      </div>
    </div>
    <div class="card">
      <div class="card-title"><span class="ct-icon">✏️</span> 수정: "안녕하세요" <span class="pill pill-green" style="margin-left:4px">기초 어휘</span></div>
      <div class="form-grid">
        <div class="form-row">
          <label class="fl">단어 (한글)</label>
          <input class="fi" type="text" value="안녕하세요">
        </div>
        <div class="form-row">
          <label class="fl">카테고리</label>
          <select class="fi">
            <option selected>기초 어휘</option>
            <option>비상 상황</option>
          </select>
        </div>
        <div class="form-row">
          <label class="fl">난이도</label>
          <select class="fi"><option selected>초급</option><option>중급</option><option>고급</option></select>
        </div>
        <div class="form-row">
          <label class="fl">중요도 태그</label>
          <select class="fi"><option selected>필수</option><option>일반</option><option>비상</option></select>
        </div>
        <div class="form-row full">
          <label class="fl">동영상 URL</label>
          <input class="fi" type="text" value="https://cdn.signbridge.kr/videos/hello.mp4">
        </div>
        <div class="form-row full">
          <label class="fl">설명 / 메모</label>
          <textarea class="fi">가장 기본적인 인사말. 오른손을 이마에서 앞으로 내리는 동작.</textarea>
        </div>
        <div class="form-actions">
          <button class="topbar-btn btn-primary" onclick="showToast('단어가 수정되었습니다 ✓', '#2d9b6f')">💾 저장</button>
          <button class="topbar-btn btn-ghost">취소</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ PAGE: WORD DELETE ══════════ -->
  <div class="content page" id="page-word-delete">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">단어 관리</div>
        <div class="section-hd">단어 삭제</div>
        <div class="section-sub">삭제한 단어는 복구할 수 없습니다. 신중하게 진행하세요.</div>
      </div>
    </div>
    <div class="filter-bar">
      <div class="search-wrap">
        <span class="si">🔍</span>
        <input type="text" placeholder="삭제할 단어 검색...">
      </div>
      <select class="filter-select">
        <option>전체 카테고리</option>
        <option>기초 어휘</option>
        <option>비상 상황</option>
      </select>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th><input type="checkbox" id="select-all-words"></th><th>단어 ID</th><th>단어</th><th>카테고리</th><th>난이도</th><th>등록일</th><th>작업</th></tr>
        </thead>
        <tbody id="word-delete-tbody"></tbody>
      </table>
    </div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-top:14px">
      <div class="pagination">
        <button class="pg-btn">‹</button>
        <button class="pg-btn active">1</button>
        <button class="pg-btn">2</button>
        <button class="pg-btn">›</button>
      </div>
      <button class="topbar-btn btn-danger" onclick="openModal('modal-word-delete-bulk')">🗑 선택 삭제</button>
    </div>
  </div>

  <!-- ══════════ PAGE: BOARD LIST ══════════ -->
  <div class="content page" id="page-board-list">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">게시판 관리</div>
        <div class="section-hd">게시글 목록</div>
        <div class="section-sub">카테고리 파라미터로 필터링 가능 <span class="topbar-path" style="font-size:11px">/admin/board/list?category=</span></div>
      </div>
    </div>

    <div class="tabs">
      <div class="tab active" onclick="switchTab(this,'board-all')">전체</div>
      <div class="tab" onclick="switchTab(this,'board-normal')">일반</div>
      <div class="tab" onclick="switchTab(this,'board-question')">질문</div>
      <div class="tab" onclick="switchTab(this,'board-notice')">공지</div>
    </div>

    <div class="filter-bar">
      <div class="search-wrap">
        <span class="si">🔍</span>
        <input type="text" placeholder="제목, 작성자, 내용 검색...">
      </div>
      <select class="filter-select">
        <option>최신순</option>
        <option>오래된순</option>
        <option>조회수순</option>
      </select>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>#</th><th>카테고리</th><th>제목</th><th>작성자</th><th>작성일</th><th>조회</th><th>작업</th></tr>
        </thead>
        <tbody id="board-tbody"></tbody>
      </table>
    </div>
    <div class="pagination">
      <button class="pg-btn">‹</button>
      <button class="pg-btn active">1</button>
      <button class="pg-btn">2</button>
      <button class="pg-btn">3</button>
      <button class="pg-btn">›</button>
    </div>
  </div>

  <!-- ══════════ PAGE: QUESTION ERROR ══════════ -->
  <div class="content page" id="page-question-error">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">문의 / 신고</div>
        <div class="section-hd">오류 신고 확인</div>
        <div class="section-sub">미처리 신고 4건이 있습니다</div>
      </div>
    </div>
    <div class="tabs">
      <div class="tab active">미처리 <span class="pill pill-red" style="margin-left:4px;padding:1px 7px">4</span></div>
      <div class="tab">처리 완료</div>
      <div class="tab">전체</div>
    </div>
    <div style="display:flex;flex-direction:column;gap:12px" id="error-list"></div>
  </div>

  <!-- ══════════ PAGE: QUESTION ADD ══════════ -->
  <div class="content page" id="page-question-add">
    <div class="page-header">
      <div>
        <div class="section-eyebrow">문의 / 신고</div>
        <div class="section-hd">단어 추가 요청 확인</div>
        <div class="section-sub">미처리 요청 9건이 있습니다</div>
      </div>
    </div>
    <div class="tabs">
      <div class="tab active">미처리 <span class="pill pill-amber" style="margin-left:4px;padding:1px 7px">9</span></div>
      <div class="tab">승인됨</div>
      <div class="tab">거절됨</div>
    </div>
    <div style="display:flex;flex-direction:column;gap:12px" id="request-list"></div>
  </div>

</div><!-- /main -->

<!-- ═══════════ MODALS ═══════════ -->
<div class="modal-overlay" id="modal-stop">
  <div class="modal">
    <div class="modal-title">⏸ 유저 정지</div>
    <div class="modal-desc">
      <b>김지수</b> 계정을 정지하시겠습니까?<br>
      정지 기간 동안 로그인 및 서비스 이용이 불가합니다.
      <div style="margin-top:14px">
        <label class="fl" style="display:block;margin-bottom:6px">정지 기간</label>
        <select class="fi">
          <option>3일</option><option>7일</option><option>14일</option><option>30일</option><option>영구 정지</option>
        </select>
        <label class="fl" style="display:block;margin:10px 0 6px">사유</label>
        <textarea class="fi" style="min-height:70px" placeholder="정지 사유를 입력하세요"></textarea>
      </div>
    </div>
    <div class="modal-actions">
      <button class="topbar-btn btn-ghost" onclick="closeModal('modal-stop')">취소</button>
      <button class="topbar-btn btn-warning" onclick="closeModal('modal-stop');showToast('계정이 정지되었습니다', '#d4840a')">정지 적용</button>
    </div>
  </div>
</div>

<div class="modal-overlay" id="modal-delete">
  <div class="modal">
    <div class="modal-title">🗑 유저 강퇴</div>
    <div class="modal-desc">
      <b>김지수</b> 계정을 영구 강퇴하시겠습니까?<br>
      이 작업은 <b style="color:var(--rose)">되돌릴 수 없습니다</b>. 모든 데이터가 삭제됩니다.
      <div style="margin-top:14px">
        <label class="fl" style="display:block;margin-bottom:6px">강퇴 사유</label>
        <textarea class="fi" style="min-height:70px" placeholder="강퇴 사유를 입력하세요"></textarea>
      </div>
    </div>
    <div class="modal-actions">
      <button class="topbar-btn btn-ghost" onclick="closeModal('modal-delete')">취소</button>
      <button class="topbar-btn btn-danger" onclick="closeModal('modal-delete');showToast('계정이 삭제되었습니다', '#c0392b')">강퇴 확인</button>
    </div>
  </div>
</div>

<div class="modal-overlay" id="modal-board-delete">
  <div class="modal">
    <div class="modal-title">🗑 게시글 삭제</div>
    <div class="modal-desc" id="modal-board-delete-desc">이 게시글을 삭제하시겠습니까? 삭제된 게시글은 복구할 수 없습니다.</div>
    <div class="modal-actions">
      <button class="topbar-btn btn-ghost" onclick="closeModal('modal-board-delete')">취소</button>
      <button class="topbar-btn btn-danger" onclick="closeModal('modal-board-delete');showToast('게시글이 삭제되었습니다', '#c0392b')">삭제</button>
    </div>
  </div>
</div>

<div class="modal-overlay" id="modal-word-delete-bulk">
  <div class="modal">
    <div class="modal-title">🗑 선택 단어 삭제</div>
    <div class="modal-desc">선택한 단어를 모두 삭제하시겠습니까? 이 작업은 <b style="color:var(--rose)">되돌릴 수 없습니다</b>.</div>
    <div class="modal-actions">
      <button class="topbar-btn btn-ghost" onclick="closeModal('modal-word-delete-bulk')">취소</button>
      <button class="topbar-btn btn-danger" onclick="closeModal('modal-word-delete-bulk');showToast('선택된 단어가 삭제되었습니다', '#c0392b')">삭제 확인</button>
    </div>
  </div>
</div>

<!-- TOAST CONTAINER -->
<div class="toast-wrap" id="toast-wrap"></div>

</body>
</html>
