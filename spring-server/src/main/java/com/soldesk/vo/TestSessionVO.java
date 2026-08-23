package com.soldesk.vo;

import java.util.Date;

public class TestSessionVO {
    private Long testSessionId;
    private int memberId;
    private String testSessionType;
    private Integer numOfQuestion;
    private Integer correctCount;
    private Integer score;
    private Date startedDate;
    private Date endedDate;

    public Long getTestSessionId() { return testSessionId; }
    public void setTestSessionId(Long testSessionId) { this.testSessionId = testSessionId; }

    public int getMemberId() { return memberId; }
    public void setMemberId(int memberId) { this.memberId = memberId; }

    public String getTestSessionType() { return testSessionType; }
    public void setTestSessionType(String testSessionType) { this.testSessionType = testSessionType; }

    public Integer getNumOfQuestion() { return numOfQuestion; }
    public void setNumOfQuestion(Integer numOfQuestion) { this.numOfQuestion = numOfQuestion; }

    public Integer getCorrectCount() { return correctCount; }
    public void setCorrectCount(Integer correctCount) { this.correctCount = correctCount; }

    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }

    public Date getStartedDate() { return startedDate; }
    public void setStartedDate(Date startedDate) { this.startedDate = startedDate; }

    public Date getEndedDate() { return endedDate; }
    public void setEndedDate(Date endedDate) { this.endedDate = endedDate; }
}