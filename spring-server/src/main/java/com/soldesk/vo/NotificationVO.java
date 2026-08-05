package com.soldesk.vo;

import java.time.LocalDateTime;

public class NotificationVO {
    int notificationId;
    int memberId;
    String notificationType;
    String title;
    String content; 
    String linkUrl;
    char isRead;
    LocalDateTime regDate;
    LocalDateTime readDate;
    public int getNotificationId() {
        return notificationId;
    }
    public void setNotificationId(int notificationId) {
        this.notificationId = notificationId;
    }
    public int getMemberId() {
        return memberId;
    }
    public void setMemberId(int memberId) {
        this.memberId = memberId;
    }
    public String getNotificationType() {
        return notificationType;
    }
    public void setNotificationType(String notificationType) {
        this.notificationType = notificationType;
    }
    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
    public String getContent() {
        return content;
    }
    public void setContent(String content) {
        this.content = content;
    }
    public String getLinkUrl() {
        return linkUrl;
    }
    public void setLinkUrl(String linkUrl) {
        this.linkUrl = linkUrl;
    }
    public char getIsRead() {
        return isRead;
    }
    public void setIsRead(char isRead) {
        this.isRead = isRead;
    }
    public LocalDateTime getRegDate() {
        return regDate;
    }
    public void setRegDate(LocalDateTime regDate) {
        this.regDate = regDate;
    }
    public LocalDateTime getReadDate() {
        return readDate;
    }
    public void setReadDate(LocalDateTime readDate) {
        this.readDate = readDate;
    }
    

    
}
