<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 회원가입</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body class="page-register">

<jsp:include page="../includes/header.jsp" />

<div class="auth-wrap">
  <div class="auth-box">
    <h2>회원가입</h2>

    <form action="/member/join" method="post" id="joinForm">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}">
      <div class="form-group">
        <label class="form-label" for="name">이름</label>
        <spring:bind path="joinMember.memberName">
          <input type="text" id="name" name="memberName" class="form-input" placeholder="이름을 입력하세요" autocomplete="name" value="${status.value}">
          <div class="form-error">
            <c:if test="${status.error}">${status.errorMessage}</c:if>
          </div>
        </spring:bind>
      </div>
      <div class="form-group">
      <label class="form-label" for="email">이메일</label>
        <spring:bind path="joinMember.memberEmail">
          <div class="input-with-btn">
            <input type="email" id="email" name="memberEmail" class="form-input" placeholder="example@email.com" autocomplete="email" value="${status.value}">
            <button type="button" id="emailCheckBtn" class="btn btn-ghost">중복확인</button>
          </div>
          <div class="form-error" id="emailMsg">
            <c:if test="${status.error}">${status.errorMessage}</c:if>
          </div>
        </spring:bind>
    
      </div>
      <div class="form-group">
        <label class="form-label" for="password">비밀번호</label>
        <spring:bind path="joinMember.memberPassword">
          <input type="password" id="password" name="memberPassword" class="form-input" placeholder="8자 이상 입력하세요" autocomplete="new-password">
          <c:choose>
            <c:when test="${status.error}">
              <div class="form-error">${status.errorMessage}</div>
            </c:when>
            <c:otherwise>
              <div class="form-hint">영문, 숫자 포함 8자 이상</div>
            </c:otherwise>
          </c:choose>
        </spring:bind>
      </div>
      <div class="form-group">
        <label class="form-label" for="password2">비밀번호 확인</label>
        <spring:bind path="joinMember.memberPasswordConfirm">
          <input type="password" id="passwordConfirm" name="memberPasswordConfirm" class="form-input" placeholder="비밀번호를 다시 입력하세요" autocomplete="new-password">
          <div class="form-error" id="passwordConfirmMsg">
            <c:if test="${status.error}">${status.errorMessage}</c:if>
          </div>
        </spring:bind>
      </div>
      <input type="text" name="website" style="position:absolute; left:-9999px;" tabindex="-1" autocomplete="off">
      <button type="submit" class="btn btn-primary btn-full">회원가입 완료</button>
    </form>

    <div class="auth-footer">
      이미 계정이 있으신가요? <a href="/member/login">로그인</a>
    </div>
  </div>
</div>

<jsp:include page="../includes/footer.jsp" />

<script>
    const name = document.getElementById('name');
    const email = document.getElementById('email');
    const emailCheckBtn = document.getElementById('emailCheckBtn');
    const password = document.getElementById('password');
    const passwordConfirm = document.getElementById('passwordConfirm');

    const emailMsg = document.getElementById('emailMsg');
    const passwordConfirmMsg = document.getElementById('passwordConfirmMsg');
    const joinForm = document.getElementById('joinForm');

    let isChecked = false;
    email.addEventListener('input', () => {
        isChecked = false;
        emailMsg.textContent = '';
        emailMsg.className = 'form-error';
    });

    emailCheckBtn.addEventListener('click', () => {
        const emailInput = email.value.trim();
        if(!emailInput) {
            emailMsg.textContent = '이메일을 입력해주세요'
            emailMsg.className = 'form-error';
            return;
        }

        fetch('/member/check-email?memberEmail=' + encodeURIComponent(emailInput))
            .then(function(response) {
                return response.json()
            })
            .then(function(data) {
                if(data.available) {
                    isChecked = true;
                    emailMsg.textContent = ''
                }
                emailMsg.className = data.available ? 'form-hint' : 'form-error';
                emailMsg.textContent = data.message;
            })
            .catch(function(error) {
                console.log('이메일 확인 중 오류 발생, ' + error.message)
                emailMsg.textContent = '이메일 확인 중 오류가 발생했습니다';
                emailMsg.className = 'form-error';
            }); 
    });

    joinForm.addEventListener('submit', function(event) {
        if(!name.value.trim() ||
         !email.value.trim() || 
         !password.value.trim() || 
         !passwordConfirm.value.trim()) {
          return;
        }
        if(isChecked == false) {
          event.preventDefault();
          emailMsg.textContent = '이메일 중복확인이 필요합니다';
          emailMsg.className = 'form-error';
        }
        if(passwordConfirm.value != password.value) {
          event.preventDefault();
          passwordConfirmMsg.textContent = '비밀번호가 일치하지 않습니다';
        }
    });
</script>

</body>
</html>
