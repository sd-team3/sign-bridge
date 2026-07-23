<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SignBridge - 수어 시험 결과</title>
<link rel="stylesheet" href="/resources/css/shared.css">
</head>
<body>

<jsp:include page="../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="result-hero">
      <div class="result-icon" id="r-icon">🎉</div>
      <div class="result-verdict pass" id="r-verdict">합격</div>
      <div class="result-sub" id="r-sub">기준 점수(70점)를 넘었어요. 잘 하셨습니다!</div>
    </div>

    <div class="result-stats">
      <div class="result-stat"><div class="num" id="r-score">82점</div><div class="lbl">최종 점수</div></div>
      <div class="result-stat"><div class="num" id="r-correct">8 / 10</div><div class="lbl">정답 수</div></div>
      <div class="result-stat warn"><div class="num" id="r-acc">91%</div><div class="lbl">평균 인식 정확도</div></div>
      <div class="result-stat danger"><div class="num" id="r-wrong">2</div><div class="lbl">틀린 문제</div></div>
    </div>

    <div class="wrong-list-card">
      <h3>⚠️ 틀린 단어 목록</h3>
      <table class="wrong-table">
        <thead>
          <tr>
            <th>#</th><th>단어</th><th>유형</th><th>카테고리</th><th>내 답 → 정답</th><th></th>
          </tr>
        </thead>
        <tbody id="wrong-tbody">
          <tr>
            <td style="color:var(--text-sub); font-size:14px;">3번</td>
            <td style="font-size:17px; font-weight:900;">🌍 지진</td>
            <td><span class="wrong-badge quiz">객관식</span></td>
            <td style="font-size:13px; color:var(--text-sub);">비상 어휘</td>
            <td style="font-size:14px;"><span style="color:var(--danger);">대피소</span> → <span style="color:var(--primary);">지진</span></td>
            <td><a href="learn_word_detail.html" class="retry-tag">다시 학습</a></td>
          </tr>
          <tr>
            <td style="color:var(--text-sub); font-size:14px;">7번</td>
            <td style="font-size:17px; font-weight:900;">🚒 소방서</td>
            <td><span class="wrong-badge cam">수어 인식</span></td>
            <td style="font-size:13px; color:var(--text-sub);">비상 어휘</td>
            <td style="font-size:14px;"><span style="color:var(--danger);">인식 실패</span> → <span style="color:var(--primary);">소방서</span></td>
            <td><a href="learn_word_detail.html" class="retry-tag">다시 학습</a></td>
          </tr>
        </tbody>
      </table>
    </div>

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
