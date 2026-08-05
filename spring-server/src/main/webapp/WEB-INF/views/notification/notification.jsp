<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<div class="notification-wrapper">
    <button id="notificationBtn" class="btn btn-ghost btn-sm notification-btn">
        알림
        <span id="notificationBadge" class="notification-badge"></span>
    </button>

    <div id="notificationDropdown" class="notification-dropdown">
        <ul id="notificationList" class="notification-list">
            <li class="notification-empty">알림이 없습니다</li>
        </ul>
    </div>
</div>