package com.soldesk.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.NotificationMapper;
import com.soldesk.vo.NotificationVO;

@Service
public class NotificationService {

    @Autowired
    private NotificationMapper notificationMapper;

    @Autowired
    private SseService sseService;
    
    public void notifyUser(int userId, String title, String content, String linkUrl,String notificationType) {
        NotificationVO vo = new NotificationVO();
        vo.setMemberId(userId);
        vo.setTitle(title);
        vo.setContent(content);
        vo.setNotificationType(notificationType);
        vo.setLinkUrl(linkUrl);

        notificationMapper.notifyUser(vo);

        Map<String, Object> payload = new HashMap<>();
        payload.put("notificationId", vo.getNotificationId());
        payload.put("title", title);
        payload.put("content", content);
        payload.put("linkUrl", linkUrl);

        sseService.sendToClient(userId, "notification", payload);
    }

    public List<NotificationVO> getNotificationList (int memberId) {
        return notificationMapper.notiList(memberId);
    }

    public void readNotification(int notificationId) {
        notificationMapper.isRead(notificationId);
    }

}
