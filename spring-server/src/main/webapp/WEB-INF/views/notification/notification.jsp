<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<div class="notification-wrap" style="position:relative; display:inline-block;">
    <button id="notificationBtn" class="btn btn-ghost btn-sm" style="position:relative;">
        알림
        <span id="notificationBadge" 
              style="display:none; position:absolute; top:-4px; right:-4px; 
                     background:#e53935; color:#fff; border-radius:50%; 
                     font-size:10px; padding:2px 5px;">0</span>
    </button>

    <div id="notificationDropdown" 
         style="display:none; position:absolute; right:0; top:36px; width:280px; 
                background:#fff; border:1px solid #ddd; border-radius:8px; 
                box-shadow:0 4px 12px rgba(0,0,0,0.1); z-index:1000;">
        <ul id="notificationList" style="list-style:none; margin:0; padding:8px 0; max-height:320px; overflow-y:auto;">
            <li style="padding:12px; color:#999; text-align:center;">알림이 없습니다</li>
        </ul>
    </div>
</div>