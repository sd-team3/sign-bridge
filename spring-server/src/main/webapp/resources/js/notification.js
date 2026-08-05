// 알림창 기능
document.addEventListener('DOMContentLoaded', function() {
    const btn = document.getElementById('notificationBtn');
    const dropdown = document.getElementById('notificationDropdown');

    btn.addEventListener('click', function() {
        dropdown.style.display = dropdown.style.display === 'none' ? 'block' : 'none';
    });
    document.addEventListener('click', function(e) {
        if (!btn.contains(e.target) && !dropdown.contains(e.target)) {
            dropdown.style.display = 'none';
        }
    });

    initNotificationSSE();
});

let unreadCount = 0;

function addNotificationToUI(title, content) {
    unreadCount++;
    const badge = document.getElementById('notificationBadge');
    badge.textContent = unreadCount;
    badge.style.display = 'inline-block';

    const list = document.getElementById('notificationList');
    if (list.children.length === 1 && list.children[0].textContent === '알림이 없습니다') {
        list.innerHTML = '';
    }
    const li = document.createElement('li');
    li.style.padding = '10px 12px';
    li.style.borderBottom = '1px solid #f0f0f0';
    li.innerHTML = '<strong>' + title + '</strong><br><span style="font-size:13px;color:#666;">' + content + '</span>';
    list.prepend(li);
}

// 알림기능 
function initNotificationSSE() {
    fetch(window.ctx + '/notification/me')
        .then(res => res.json())
        .then(data => {
            if (!data.memberId) return;

            const eventSource = new EventSource(window.ctx + '/sse/subscribe/' + data.memberId);

            eventSource.addEventListener('notification', function(event) {
                const payload = JSON.parse(event.data);
                console.log("알림 : ", payload);
                addNotificationToUI(payload.title, payload.content);
            });

            eventSource.onerror = (error) => {
                console.error("통신 에러 : ", error);
            };
        })
        .catch(err => console.error("memberId 못찾겠음 ", err));
}