package com.soldesk.vo;

import java.time.LocalDateTime;

public class WordHistoryVO {
    private Integer testSessionDetailId;
    private Integer signWordId;
    private String signWordName;
    private String testSessionType;
    private String isCorrect;
    private LocalDateTime answerDate;
    
    public Integer getTestSessionDetailId() {
        return testSessionDetailId;
    }
    public void setTestSessionDetailId(Integer testSessionDetailId) {
        this.testSessionDetailId = testSessionDetailId;
    }
    public Integer getSignWordId() {
        return signWordId;
    }
    public void setSignWordId(Integer signWordId) {
        this.signWordId = signWordId;
    }
    public String getSignWordName() {
        return signWordName;
    }
    public void setSignWordName(String signWordName) {
        this.signWordName = signWordName;
    }
    public String getTestSessionType() {
        return testSessionType;
    }
    public void setTestSessionType(String testSessionType) {
        this.testSessionType = testSessionType;
    }
    public String getIsCorrect() {
        return isCorrect;
    }
    public void setIsCorrect(String isCorrect) {
        this.isCorrect = isCorrect;
    }
    public LocalDateTime getAnswerDate() {
        return answerDate;
    }
    public void setAnswerDate(LocalDateTime answerDate) {
        this.answerDate = answerDate;
    }
}
