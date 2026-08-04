package com.soldesk.vo;

import java.time.LocalDateTime;

public class NotificationVO {
    int notification_id;
    int member_id;
    String notification_type;
    String title;
    String content; 
    String link_url;
    char is_read;
    LocalDateTime reg_date;
    LocalDateTime read_date;
    public int getNotification_id() {
        return notification_id;
    }
    public void setNotification_id(int notification_id) {
        this.notification_id = notification_id;
    }
    public int getMember_id() {
        return member_id;
    }
    public void setMember_id(int member_id) {
        this.member_id = member_id;
    }
    public String getNotification_type() {
        return notification_type;
    }
    public void setNotification_type(String notification_type) {
        this.notification_type = notification_type;
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
    public String getLink_url() {
        return link_url;
    }
    public void setLink_url(String link_url) {
        this.link_url = link_url;
    }
    public char getIs_read() {
        return is_read;
    }
    public void setIs_read(char is_read) {
        this.is_read = is_read;
    }
    public LocalDateTime getReg_date() {
        return reg_date;
    }
    public void setReg_date(LocalDateTime reg_date) {
        this.reg_date = reg_date;
    }
    public LocalDateTime getRead_date() {
        return read_date;
    }
    public void setRead_date(LocalDateTime read_date) {
        this.read_date = read_date;
    }

    
}
