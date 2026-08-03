package com.soldesk.mapper;

public interface NotificationMapper {

    void notifyUser(int userId, String title, String content);
    
} 