package com.soldesk.vo;

import java.time.LocalDateTime;

public class InquiryVO {
    private Long inquiryId;
    private Long memberId;
    private String category;
    private String title;
    private String content;
    private String status;
    private String answerContent;
    private Long answeredMemberId;
    private LocalDateTime answeredDate;
    private LocalDateTime regDate;
    private LocalDateTime modDate;
    private String regDateStr;
    private String memberName;

    public String getMemberName() {
        return memberName;
    }
    public void setMemberName(String memberName) {
        this.memberName = memberName;
    }
    public Long getInquiryId() {
        return inquiryId;
    }
    public void setInquiryId(Long inquiryId) {
        this.inquiryId = inquiryId;
    }
    public Long getMemberId() {
        return memberId;
    }
    public void setMemberId(Long memberId) {
        this.memberId = memberId;
    }
    public String getCategory() {
        return category;
    }
    public void setCategory(String category) {
        this.category = category;
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
    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }
    public String getAnswerContent() {
        return answerContent;
    }
    public void setAnswerContent(String answerContent) {
        this.answerContent = answerContent;
    }
    public Long getAnsweredMemberId() {
        return answeredMemberId;
    }
    public void setAnsweredMemberId(Long answeredMemberId) {
        this.answeredMemberId = answeredMemberId;
    }
    public LocalDateTime getAnsweredDate() {
        return answeredDate;
    }
    public void setAnsweredDate(LocalDateTime answeredDate) {
        this.answeredDate = answeredDate;
    }
    public LocalDateTime getRegDate() {
        return regDate;
    }
    public void setRegDate(LocalDateTime regDate) {
        this.regDate = regDate;
    }
    public LocalDateTime getModDate() {
        return modDate;
    }
    public void setModDate(LocalDateTime modDate) {
        this.modDate = modDate;
    }
    public String getRegDateStr() {
        return regDateStr;
    }
    public void setRegDateStr(String regDateStr) {
        this.regDateStr = regDateStr;
    }
    
}
