package com.soldesk.service;

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
        notificationMapper.notifyUser(userId, title, content);

        sseService.sendToClient(userId, title, content);
    }

}
