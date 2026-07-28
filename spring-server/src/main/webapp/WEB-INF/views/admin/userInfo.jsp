<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="유저 상세" scope="request" />
<c:set var="pagePath" value="/admin/user/info" scope="request" />
<c:set var="activeMenu" value="user-info" scope="request" />
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - ${pageTitle}</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/resources/css/admin.css">
</head>
<body>

<jsp:include page="includes/header.jsp" />


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
  <div class="card" style="text-align:center">
    <div style="width:72px;height:72px;border-radius:50%;background:var(--p);display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:700;color:#fff;margin:0 auto 14px">${user.initial}</div>
    <div style="font-size:17px;font-weight:800;color:var(--ink);margin-bottom:4px">${userName}</div>
    <div style="font-size:13px;color:var(--ink3);margin-bottom:12px">${userEmail}</div>
    <span class="pill pill-green" style="margin-bottom:16px">${user.roleLabel}</span>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:12px;text-align:left">
      <div class="detail-row"><span class="detail-label">학습 수</span><span class="detail-value mono">${user.studyCount}</span></div>
      <div class="detail-row"><span class="detail-label">정확도</span><span class="detail-value mono">${user.accuracy}%</span></div>
      <div class="detail-row"><span class="detail-label">티어</span><span class="detail-value">${user.tierLabel}</span></div>
      <div class="detail-row"><span class="detail-label">XP</span><span class="detail-value mono">${user.xp}</span></div>
    </div>
  </div>

  <div style="display:flex;flex-direction:column;gap:16px">
    <div class="card">
      <div class="card-title"><span class="ct-icon">📋</span> 계정 정보</div>
      <div class="detail-grid">
        <div class="detail-row"><span class="detail-label">UID</span><span class="detail-value mono">${member.memberId}</span></div>
        <div class="detail-row"><span class="detail-label">이름</span><span class="detail-value">${member.memberName}</span></div>
        <div class="detail-row"><span class="detail-label">이메일</span><span class="detail-value mono">${member.memberEmail}</span></div>
        <div class="detail-row"><span class="detail-label">가입일</span><span class="detail-value mono">${member.regDate}</span></div>
        <div class="detail-row">
          <span class="detail-label">가입 방법</span>
          <span class="detail-value">
            <c:choose>
              <c:when test="${not empty member.provider}">
                ${member.provider}
              </c:when>
              <c:otherwise>
                일반가입
              </c:otherwise>
            </c:choose>
          </span>
        </div>
        <div class="detail-row"><span class="detail-label">계정 상태</span><span class="pill ${user.statusPillClass}">${member.status}</span></div>
      </div>
    </div>
    <div class="card">
      <div class="card-title"><span class="ct-icon">📝</span> 최근 게시글</div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>번호</th><th>제목</th><th>카테고리</th><th>작성일</th></tr></thead>
          <tbody>
            <c:forEach var="post" items="${user.recentPosts}">
              <tr>
                <td class="td-mono">#${post.id}</td>
                <td>${post.title}</td>
                <td><span class="pill ${post.categoryPillClass}">${post.categoryLabel}</span></td>
                <td class="td-mono">${post.createdDate}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<!-- 정지 모달 -->
<div class="modal-overlay" id="modal-stop">
  <div class="modal">
    <form method="post" action="${pageContext.request.contextPath}/admin/user/stop">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
      <input type="hidden" name="memberId" value="${member.memberId}">
      <div class="modal-title">⏸ 유저 정지</div>
      <div class="modal-desc">
        <b>${member.memberName}</b> 계정을 정지하시겠습니까?<br>
        정지 기간 동안 로그인 및 서비스 이용이 불가합니다.
        <div style="margin-top:14px">
          <label class="fl" style="display:block;margin-bottom:6px">정지 기간</label>
          <select class="fi" name="suspendDays">
            <option value="3">3일</option><option value="7">7일</option><option value="14">14일</option><option value="30">30일</option><option value="permanent">영구 정지</option>
          </select>
          <label class="fl" style="display:block;margin:10px 0 6px">사유</label>
          <textarea class="fi" name="reason" style="min-height:70px" placeholder="정지 사유를 입력하세요"></textarea>
        </div>
      </div>
      <div class="modal-actions">
        <button type="button" class="topbar-btn btn-ghost" onclick="closeModal('modal-stop')">취소</button>
        <button type="submit" class="topbar-btn btn-warning">정지 적용</button>
      </div>
    </form>
  </div>
</div>

<!-- 강퇴 모달 -->
<div class="modal-overlay" id="modal-delete">
  <div class="modal">
    <form method="post" action="${pageContext.request.contextPath}/admin/user/delete">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
      <input type="hidden" name="memberId" value="${member.memberId}">
      <div class="modal-title">🗑 유저 강퇴</div>
      <div class="modal-desc">
        <b>${member.memberName}</b> 계정을 영구 강퇴하시겠습니까?<br>
        이 작업은 <b style="color:var(--rose)">되돌릴 수 없습니다</b>. 모든 데이터가 삭제됩니다.
      </div>
      <div class="modal-actions">
        <button type="button" class="topbar-btn btn-ghost" onclick="closeModal('modal-delete')">취소</button>
        <button type="submit" class="topbar-btn btn-danger">강퇴 확인</button>
      </div>
    </form>
  </div>
</div>

<jsp:include page="includes/footer.jsp" />

<script>
  // 정지 모달 열고 닫기
  function openModal(id) {
    document.getElementById(id).classList.add('open');
  }
  function closeModal(id) {
    document.getElementById(id).classList.remove('open');
  }
  
</script>

</body>
</html>
