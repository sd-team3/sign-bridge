<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - 수어 시험 결과</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <c:set var="passScore" value="${empty param.pass ? 70 : param.pass}" />
    <c:set var="isPass" value="${session.score >= passScore}" />

        <div class="result-hero">
          <div class="result-icon" id="r-icon">${isPass ? '🎉' : '😢'}</div>
          <div class="result-verdict ${isPass ? 'pass' : 'fail'}" id="r-verdict">${isPass ? '합격' : '불합격'}</div>
          <div class="result-sub" id="r-sub">
            <c:choose>
              <c:when test="${isPass}">${passScore}점을 넘었어요. 합격입니다!</c:when>
              <c:otherwise>${passScore}점에 도달하지 못했어요. 다시 도전해보세요!</c:otherwise>
            </c:choose>
          </div>
        </div>

    <div class="result-stats">
      <div class="result-stat"><div class="num" id="r-score">${session.score}점</div><div class="lbl">최종 점수</div></div>
      <div class="result-stat"><div class="num" id="r-correct">${session.correctCount} / ${session.numOfQuestion}</div><div class="lbl">정답 수</div></div>
      <div class="result-stat danger"><div class="num" id="r-wrong">${session.numOfQuestion - session.correctCount}</div><div class="lbl">틀린 문제</div></div>
    </div>

    <c:if test="${not empty wrongList}">
    <div class="wrong-list-card">
      <h3>⚠️ 틀린 단어 목록</h3>
      <table class="wrong-table">
        <thead>
          <tr>
            <th>#</th><th>단어</th><th>내 답 → 정답</th><th></th>
          </tr>
        </thead>
        <tbody id="wrong-tbody">
          <c:forEach items="${wrongList}" var="w">
          <tr>
            <td style="color:var(--text-sub); font-size:14px;">${w.questionNo}번</td>
            <td style="font-size:17px; font-weight:900;">${w.signWordName}</td>
            <td style="font-size:14px;"><span style="color:var(--danger);">${w.userAnswer}</span> → <span style="color:var(--primary);">${w.signWordName}</span></td>
            <td><a href="/learn/dict/detail?word=${w.signWordName}" class="retry-tag">다시 학습</a></td>
          </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    </c:if>

    <div class="result-actions">
      <a href="/" class="btn btn-ghost btn-lg">⚙️ 메인으로 돌아가기</a>
      <a href="/mypage/note" class="btn btn-ghost btn-lg">📋 오답 노트 바로가기</a>
      <a href="/exam/setup" class="btn btn-primary btn-lg">🔄 시험 페이지 돌아가기</a>
    </div>

  </div>
</main>

<jsp:include page="../includes/footer.jsp" />

</body>
</html>
