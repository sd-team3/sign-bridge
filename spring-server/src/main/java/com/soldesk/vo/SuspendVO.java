package com.soldesk.vo;

import java.time.LocalDateTime;

public class SuspendVO {
    int suspension_id;
    int member_id;
    int admin_id;
    String reason;
    LocalDateTime start_date;
    LocalDateTime end_date;
    public int getSuspension_id() {
        return suspension_id;
    }
    public void setSuspension_id(int suspension_id) {
        this.suspension_id = suspension_id;
    }
    public int getMember_id() {
        return member_id;
    }
    public void setMember_id(int member_id) {
        this.member_id = member_id;
    }
    public int getAdmin_id() {
        return admin_id;
    }
    public void setAdmin_id(int admin_id) {
        this.admin_id = admin_id;
    }
    public String getReason() {
        return reason;
    }
    public void setReason(String reason) {
        this.reason = reason;
    }
    public LocalDateTime getStart_date() {
        return start_date;
    }
    public void setStart_date(LocalDateTime start_date) {
        this.start_date = start_date;
    }
    public LocalDateTime getEnd_date() {
        return end_date;
    }
    public void setEnd_date(LocalDateTime end_date) {
        this.end_date = end_date;
    } 
}
