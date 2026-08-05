package com.soldesk.vo;

import java.util.Date;

public class TestSessionDetailVO {
    private Long testSessionDetailId;
    private Long testSessionId;
    private Long signWordId;
    private Integer questionNo;
    private String userAnswer;
    private String isCorrect;   // 'Y' / 'N'
    private Date answerDate;

    public Long getTestSessionDetailId() { return testSessionDetailId; }
    public void setTestSessionDetailId(Long testSessionDetailId) { this.testSessionDetailId = testSessionDetailId; }

    public Long getTestSessionId() { return testSessionId; }
    public void setTestSessionId(Long testSessionId) { this.testSessionId = testSessionId; }

    public Long getSignWordId() { return signWordId; }
    public void setSignWordId(Long signWordId) { this.signWordId = signWordId; }

    public Integer getQuestionNo() { return questionNo; }
    public void setQuestionNo(Integer questionNo) { this.questionNo = questionNo; }

    public String getUserAnswer() { return userAnswer; }
    public void setUserAnswer(String userAnswer) { this.userAnswer = userAnswer; }

    public String getIsCorrect() { return isCorrect; }
    public void setIsCorrect(String isCorrect) { this.isCorrect = isCorrect; }

    public Date getAnswerDate() { return answerDate; }
    public void setAnswerDate(Date answerDate) { this.answerDate = answerDate; }
}