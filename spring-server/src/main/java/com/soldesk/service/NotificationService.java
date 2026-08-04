package com.soldesk.service;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.NotificationMapper;

@Service
public class NotificationService {

    @Autowired
    private NotificationMapper notificationMapper;

    @Autowired
    private SseService sseService;
    
    public void notifyUser(int userId, String title, String content) {
         System.out.println("### title.length() = " + title.length());
        notificationMapper.notifyUser(userId, title, content);

        Map<String, Object> payload = new HashMap<>();
        payload.put("title", title);
        payload.put("content", content);

        sseService.sendToClient(userId, "notification", payload);
    }

}
