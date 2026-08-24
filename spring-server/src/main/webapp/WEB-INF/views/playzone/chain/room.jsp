<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="icon" href="/resources/favicon.ico" type="image/x-icon">
<link rel="apple-touch-icon" href="/resources/images/icon-180.png">
<title>SignBridge - 끝말잇기 방</title>
<link rel="stylesheet" href="/resources/css/shared.css">
<style>
  .chain-players{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:14px;margin:20px 0}
  .chain-player{background:var(--surface);border:2px solid var(--border);border-radius:var(--radius-sm);padding:14px;text-align:center;position:relative}
  .chain-player.turn{border-color:var(--primary);box-shadow:0 0 0 3px rgba(45,155,111,.15)}
  .chain-player.eliminated{opacity:.4}
  .chain-player .host-mark{position:absolute;top:8px;left:10px;font-size:13px}
  .chain-player .lives{font-size:15px;margin-top:4px}
  .chain-player .score{font-size:13px;color:var(--text-sub)}
  .chain-turn-banner{display:flex;align-items:center;justify-content:space-between;background:var(--primary-light);border:2px solid var(--border);border-radius:var(--radius);padding:18px 24px;margin-bottom:18px}
  .chain-required-char{font-size:32px;font-weight:900;color:var(--primary)}
  .chain-cam-wrap{position:relative;width:100%;aspect-ratio:4/3;background:#111;border-radius:var(--radius-sm);overflow:hidden}
  .chain-cam-wrap video,.chain-cam-wrap canvas{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
  .chain-composed{font-size:28px;font-weight:800;text-align:center;margin-top:12px;min-height:40px}
  .chain-log{max-height:220px;overflow-y:auto;border:2px solid var(--border);border-radius:var(--radius-sm);padding:10px;font-size:14px}
  .chain-log .row{padding:4px 0;border-bottom:1px solid var(--border)}
  .chain-log .valid{color:var(--primary);font-weight:700}
  .chain-log .invalid{color:var(--danger);font-weight:700}
</style>
</head>
<body>

<jsp:include page="../../includes/header.jsp" />

<main>
  <div class="container page-body">

    <div class="page-header">
      <div>
        <h1 id="roomTitle">끝말잇기 방</h1>
        <p id="roomSubtitle">참가자를 기다리는 중...</p>
      </div>
      <div style="display:flex; gap:10px;">
        <button class="btn btn-primary" id="btnStart" style="display:none;">게임 시작</button>
        <button class="btn btn-ghost" id="btnLeave">나가기</button>
      </div>
    </div>

    <div class="chain-turn-banner" id="turnBanner" style="display:none;">
      <div>
        <div style="font-size:13px; color:var(--text-sub);">이번 턴</div>
        <div id="turnPlayerName" style="font-size:20px; font-weight:800;">-</div>
      </div>
      <div style="text-align:center;">
        <div style="font-size:13px; color:var(--text-sub);">다음 단어는</div>
        <div class="chain-required-char" id="requiredChar">아무 글자나</div>
      </div>
      <div class="timer-badge">
        <div class="timer-num" id="turnTimer">--</div>
        <div class="timer-label">남은 시간</div>
      </div>
    </div>

    <div class="chain-players" id="playerList"></div>

    <div id="gameArea" style="display:none;">
      <div class="cam-main-grid" style="display:grid; grid-template-columns:1fr 1fr; gap:20px;">
        <div>
          <div class="chain-cam-wrap">
            <video id="video" autoplay playsinline muted></video>
            <canvas id="canvas"></canvas>
          </div>
        </div>
        <div>
          <div class="card">
            <div style="font-size:13px; color:var(--text-sub);">내가 조합 중인 단어</div>
            <div class="chain-composed" id="composedText">-</div>
            <div class="progress-bar" style="height:6px; background:var(--surface2); border-radius:100px; overflow:hidden; margin-top:8px;">
              <div id="progressFill" style="height:100%; background:var(--primary); width:0%; transition:width .1s;"></div>
            </div>
            <button class="btn btn-primary btn-full" id="btnComplete" style="margin-top:16px;">✅ 단어 완성</button>
          </div>
        </div>
      </div>
    </div>

    <div id="resultArea" style="display:none;">
      <div class="page-header">
        <div>
          <h1 id="winnerTitle">🏆 게임 종료</h1>
          <p>수고하셨습니다!</p>
        </div>
        <button class="btn btn-primary" onclick="location.href='${pageContext.request.contextPath}/playzone/chain'">로비로</button>
      </div>
    </div>

    <h3 style="margin-top:24px;">진행 로그</h3>
    <div class="chain-log" id="wordLog"></div>
  </div>
</main>

<jsp:include page="../../includes/footer.jsp" />

<script>
window.CHAIN_ROOM_ID = ${roomId};
window.CHAIN_CTX = "${pageContext.request.contextPath}";
</script>
<script type="module" src="/resources/js/chain-room.js"></script>

</body>
</html>
