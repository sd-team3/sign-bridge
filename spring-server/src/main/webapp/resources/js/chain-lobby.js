const ctx = window.CHAIN_CTX || "";

function loadRooms() {
  fetch(`${ctx}/api/playzone/chain/rooms`, { credentials: "same-origin" })
    .then(res => res.json())
    .then(renderRooms)
    .catch(err => console.error("방 목록 조회 실패", err));
}

function renderRooms(rooms) {
  const list = document.getElementById("roomList");
  if (!rooms || rooms.length === 0) {
    list.innerHTML = `<div class="chain-room-empty">현재 대기 중인 방이 없어요. 첫 방을 만들어보세요!</div>`;
    return;
  }
  list.innerHTML = rooms.map(r => `
    <div class="chain-room-card">
      <h3>${escapeHtml(r.chainRoomName)}</h3>
      <span class="badge badge-primary">대기 중</span>
      <button class="btn btn-primary btn-sm" onclick="location.href='${ctx}/playzone/chain/${r.chainRoomId}'">입장하기</button>
    </div>
  `).join("");
}

function escapeHtml(s) {
  return (s || "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
}

document.getElementById("btnCreate").addEventListener("click", () => {
  document.getElementById("createModal").classList.add("show");
});
document.getElementById("btnCancelCreate").addEventListener("click", () => {
  document.getElementById("createModal").classList.remove("show");
});
document.getElementById("btnSubmitCreate").addEventListener("click", () => {
  const chainRoomName = document.getElementById("roomNameInput").value.trim();
  fetch(`${ctx}/api/playzone/chain/rooms`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "same-origin",
    body: JSON.stringify({ chainRoomName }),
  })
    .then(res => res.json())
    .then(room => { location.href = `${ctx}/playzone/chain/${room.chainRoomId}`; })
    .catch(err => console.error("방 생성 실패", err));
});

loadRooms();
setInterval(loadRooms, 4000);
