<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - 로그인</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body class="page-login">

<jsp:include page="../includes/header.jsp" />

<div class="auth-wrap">
  <div class="auth-box">
    <div class="auth-logo">
      <div class="logo-text">SignBridge</div>
      <p>수어 학습을 계속하려면 로그인하세요.</p>
    </div>

    <h2>로그인</h2>

    <form action="/member/login" method="post">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
      <div class="form-group">
        <label class="form-label" for="email">이메일</label>
        <input type="email" id="email" name="memberEmail" class="form-input" placeholder="example@email.com" autocomplete="email">
      </div>
      <div class="form-group">
        <label class="form-label" for="password">비밀번호</label>
        <input type="password" id="password" name="memberPassword" class="form-input" placeholder="비밀번호를 입력하세요" autocomplete="current-password">
      </div>
      <c:choose>
        <c:when test="${param.error == 'suspended'}">
          <div class="form-error">정지된 계정입니다.</div>
        </c:when>
        <c:when test="${param.error != null}">
          <div class="form-error">이메일 또는 비밀번호가 일치하지 않습니다</div>
        </c:when>
      </c:choose>

      <button type="submit" class="btn btn-primary btn-full" style="margin-top:8px;">로그인</button>
    </form>
        <div class="oauth-divider">
      <span>또는</span>
    </div>

    <div class="oauth-buttons">
        <a href="/oauth2/google" class="btn-oauth btn-google">
            <svg class="oauth-icon" viewBox="0 0 24 24" width="18" height="18">
            <path fill="#4285F4" d="M23.49 12.27c0-.79-.07-1.54-.2-2.27H12v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z"/>
            <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09C3.26 21.3 7.31 24 12 24z"/>
            <path fill="#FBBC05" d="M5.27 14.29c-.25-.72-.38-1.49-.38-2.29s.14-1.57.38-2.29V6.62H1.29A11.94 11.94 0 0 0 0 12c0 1.92.46 3.74 1.29 5.38l3.98-3.09z"/>
            <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.94 1.19 15.24 0 12 0 7.31 0 3.26 2.7 1.29 6.62l3.98 3.09C6.22 6.86 8.87 4.75 12 4.75z"/>
            </svg>
            Google로 로그인
        </a>

        <a href="/oauth2/naver" class="btn-oauth btn-naver">
            <svg class="oauth-icon" viewBox="0 0 24 24" width="18" height="18">
            <path fill="#ffffff" d="M16.3 12.9L8.6 1.9H1.9v20.2h6.8V11.1l7.7 11h6.7V1.9h-6.8v11z"/>
            </svg>
            네이버로 로그인
        </a>

        <a href="/oauth2/kakao" class="btn-oauth btn-kakao">
          <svg class="oauth-icon" viewBox="0 0 24 24" width="18" height="18">
            <path fill="#181600" d="M12 3C6.48 3 2 6.58 2 11c0 2.85 1.86 5.35 4.66 6.79-.2.75-.73 2.72-.84 3.14-.13.51.19.5.4.37.16-.1 2.6-1.77 3.66-2.5.68.1 1.39.15 2.12.15 5.52 0 10-3.58 10-8s-4.48-8-10-8z"/>
          </svg>
          카카오로 로그인
        </a>
    </div>

    <div class="auth-footer">
      아직 계정이 없으신가요? <a href="/member/join">회원가입</a>
    </div>
  </div>
</div>

<jsp:include page="../includes/footer.jsp" />
</body>
</html>