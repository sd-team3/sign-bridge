package com.soldesk.vo;

import java.time.LocalDateTime;

public class SuspendVO {
    int suspensionId;
    int memberId;
    int adminId;
    String reason;
    LocalDateTime startDate;
    public int getSuspensionId() {
        return suspensionId;
    }
    public void setSuspensionId(int suspensionId) {
        this.suspensionId = suspensionId;
    }
    public int getMemberId() {
        return memberId;
    }
    public void setMemberId(int memberId) {
        this.memberId = memberId;
    }
    public int getAdminId() {
        return adminId;
    }
    public void setAdminId(int adminId) {
        this.adminId = adminId;
    }
    public String getReason() {
        return reason;
    }
    public void setReason(String reason) {
        this.reason = reason;
    }
    public LocalDateTime getStartDate() {
        return startDate;
    }
    public void setStartDate(LocalDateTime startDate) {
        this.startDate = startDate;
    }
    public LocalDateTime getEndDate() {
        return endDate;
    }
    public void setEndDate(LocalDateTime endDate) {
        this.endDate = endDate;
    }
    LocalDateTime endDate; 
}
