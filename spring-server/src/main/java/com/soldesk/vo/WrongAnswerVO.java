package com.soldesk.vo;

import java.time.LocalDateTime;

public class WrongAnswerVO {
    private Integer questionNo;
    private String signWordName;
    private String userAnswer;

    private Integer testSessionDetailId;
    private Integer signWordId;
    private String signWordThumbnail;
    private LocalDateTime answerDate;
    private String testSessionType;

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
    public String getSignWordThumbnail() {
        return signWordThumbnail;
    }
    public void setSignWordThumbnail(String signWordThumbnail) {
        this.signWordThumbnail = signWordThumbnail;
    }
    public LocalDateTime getAnswerDate() {
        return answerDate;
    }
    public void setAnswerDate(LocalDateTime answerDate) {
        this.answerDate = answerDate;
    }
    public String getTestSessionType() {
        return testSessionType;
    }
    public void setTestSessionType(String testSessionType) {
        this.testSessionType = testSessionType;
    }
    
    public Integer getQuestionNo() { return questionNo; }
    public void setQuestionNo(Integer questionNo) { this.questionNo = questionNo; }

    public String getSignWordName() { return signWordName; }
    public void setSignWordName(String signWordName) { this.signWordName = signWordName; }

    public String getUserAnswer() { return userAnswer; }
    public void setUserAnswer(String userAnswer) { this.userAnswer = userAnswer; }
}