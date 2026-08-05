package com.soldesk.vo;

public class WrongAnswerVO {
    private Integer questionNo;
    private String signWordName;
    private String userAnswer;

    public Integer getQuestionNo() { return questionNo; }
    public void setQuestionNo(Integer questionNo) { this.questionNo = questionNo; }

    public String getSignWordName() { return signWordName; }
    public void setSignWordName(String signWordName) { this.signWordName = signWordName; }

    public String getUserAnswer() { return userAnswer; }
    public void setUserAnswer(String userAnswer) { this.userAnswer = userAnswer; }
}