<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - 수어 끝말잇기</title>
<link rel="stylesheet" href="/resources/css/shared.css">
<style>
  .chain-room-list{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px;margin-top:20px}
  .chain-room-card{background:var(--surface);border:2px solid var(--border);border-radius:var(--radius);padding:20px;display:flex;flex-direction:column;gap:10px}
  .chain-room-card h3{font-size:17px;font-weight:800}
  .chain-room-empty{text-align:center;color:var(--text-sub);padding:60px 0}
  #createModal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.4);align-items:center;justify-content:center;z-index:50}
  #createModal.show{display:flex}
  .modal-box{background:var(--surface);border-radius:var(--radius);padding:28px;width:360px}
  .modal-box input{width:100%;padding:10px 12px;border:2px solid var(--border);border-radius:var(--radius-sm);margin:10px 0 18px}
</style>
</head>
<body>

<jsp:include page="../../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="page-header">
      <div>
        <h1>🔗 수어 끝말잇기</h1>
        <p>최대 4명, 수어 지문자로 끝말잇기 대결! 방을 만들거나 참여해보세요.</p>
      </div>
      <button class="btn btn-primary" id="btnCreate">+ 방 만들기</button>
    </div>

    <div class="chain-room-list" id="roomList"></div>
  </div>
</main>

<div id="createModal">
  <div class="modal-box">
    <h3>새 방 만들기</h3>
    <input type="text" id="roomNameInput" placeholder="방 이름 (예: 같이해요~)" maxlength="30">
    <div style="display:flex; gap:10px; justify-content:flex-end;">
      <button class="btn btn-ghost btn-sm" id="btnCancelCreate">취소</button>
      <button class="btn btn-primary btn-sm" id="btnSubmitCreate">만들기</button>
    </div>
  </div>
</div>

<jsp:include page="../../includes/footer.jsp" />

<script>
window.CHAIN_CTX = "${pageContext.request.contextPath}";
</script>
<script src="/resources/js/chain-lobby.js"></script>
</body>
</html>
