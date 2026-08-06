package com.soldesk.vo;

public class BoardErrorReportVO {
    private int boardId;
    private String errorType;   // 오류 유형 (enum 관리: ACTION_RECOGNITION 등)
    private String relatedWord; // 오류 관련 단어 / 기능

    public int getBoardId() {
        return boardId;
    }
    public void setBoardId(int boardId) {
        this.boardId = boardId;
    }
    public String getErrorType() {
        return errorType;
    }
    public void setErrorType(String errorType) {
        this.errorType = errorType;
    }
    public String getRelatedWord() {
        return relatedWord;
    }
    public void setRelatedWord(String relatedWord) {
        this.relatedWord = relatedWord;
    }

}
