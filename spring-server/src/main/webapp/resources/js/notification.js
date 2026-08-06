const csrfToken = document.querySelector('meta[name="_csrf"]').content;
const csrfHeader = document.querySelector('meta[name="_csrf_header"]').content;

let unreadCount = 0;
let listLoaded = false;

// 페이지 로드될때 무조건 실행
document.addEventListener('DOMContentLoaded', function() {
    const btn = document.getElementById('notificationBtn');
    const dropdown = document.getElementById('notificationDropdown');

    btn.addEventListener('click', function() {
        const isOpening = dropdown.style.display === 'none';
        dropdown.style.display = isOpening ? 'block' : 'none';
        if (isOpening) {
            loadNotificationList(); 
        }
    });

    document.addEventListener('click', function(e) {
        if (!btn.contains(e.target) && !dropdown.contains(e.target)) {
            dropdown.style.display = 'none';
        }
    });

    fetchUnreadCount(); 
    initNotificationSSE();
});

// 뱃지 카운트만 조회 
function fetchUnreadCount() {
    fetch(window.ctx + '/notification/list')
        .then(res => res.json())
        .then(list => {
            unreadCount = list.length;
            updateBadge();
        })
        .catch(err => console.error('알림 카운트 못 불러옴 ', err));
}

function updateBadge() {
    const badge = document.getElementById('notificationBadge');
    if (unreadCount > 0) {
        badge.textContent = unreadCount;
        badge.style.display = 'inline-block';
    } else {
        badge.style.display = 'none';
    }
}

// 드롭다운 열 때 목록 렌더링
function loadNotificationList() {
    fetch(window.ctx + '/notification/list')
        .then(res => res.json())
        .then(list => {
            const listEl = document.getElementById('notificationList');

            if (!list || list.length === 0) {
                listEl.innerHTML = '<li class="notification-empty">알림이 없습니다</li>';
                return;
            }

            listEl.innerHTML = '';
            list.sort((a, b) => new Date(b.regDate) - new Date(a.regDate));
            list.forEach(item => listEl.appendChild(createNotificationLi(item)));

            unreadCount = list.length;
            updateBadge();
        })
        .catch(err => console.error('알림 목록 못 불러옴 ', err));
}

function createNotificationLi(item) {
    const li = document.createElement('li');
    li.className = 'notification-item';
    li.dataset.notificationId = item.notificationId;

    const a = document.createElement('a');
    a.href = item.linkUrl || '#';
    a.innerHTML = '<strong>' + item.title + '</strong><span>' + item.content + '</span>';

    a.addEventListener('click', function() {
        fetch(window.ctx + '/notification/read/' + item.notificationId, {
            method: 'POST',
            headers: { [csrfHeader]: csrfToken }
        }).catch(err => console.error('읽음 처리 실패 ', err));
    });

    li.appendChild(a);
    return li;
}

function addNotificationToUI(item) {
    unreadCount++;
    updateBadge();

    const dropdown = document.getElementById('notificationDropdown');
    if (dropdown.style.display !== 'none') {
        const list = document.getElementById('notificationList');
        if (list.children.length === 1 && list.children[0].classList.contains('notification-empty')) {
            list.innerHTML = '';
        }
        list.prepend(createNotificationLi(item));
    }
}

function initNotificationSSE() {
    fetch(window.ctx + '/notification/me')
        .then(res => res.json())
        .then(data => {
            if (!data.memberId) return;

            const eventSource = new EventSource(window.ctx + '/sse/subscribe/' + data.memberId);

            eventSource.addEventListener('notification', function(event) {
                const payload = JSON.parse(event.data);
                addNotificationToUI(payload.message);
            });

            eventSource.onerror = (error) => {
                console.error("통신 에러 : ", error);
            };
        })
        .catch(err => console.error("memberId 못찾겠음 ", err));
}