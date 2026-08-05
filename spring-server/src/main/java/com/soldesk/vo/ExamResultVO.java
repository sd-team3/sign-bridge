package com.soldesk.vo;

import java.util.List;

public class ExamResultVO {
    private TestSessionVO session;
    private List<WrongAnswerVO> wrongList;

    public TestSessionVO getSession() { return session; }
    public void setSession(TestSessionVO session) { this.session = session; }

    public List<WrongAnswerVO> getWrongList() { return wrongList; }
    public void setWrongList(List<WrongAnswerVO> wrongList) { this.wrongList = wrongList; }
}