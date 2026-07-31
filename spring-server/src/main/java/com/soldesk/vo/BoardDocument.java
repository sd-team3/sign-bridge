package com.soldesk.vo;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class BoardDocument {
    private int boardId;
    private int memberId;	
    private String boardTitle;
    private String boardContent;
    private String categoryIdx; // 게시판 유형 (enum: BoardType, NOTICE/FREE/INFO/QNA/REPORT) - 조회 시 이 값으로 필터링
    private int viewCount;
    private String noticeYn;
    private LocalDateTime regDate;
    private LocalDateTime modDate;

    private String memberName;

    public static BoardDocument from(BoardVO board) {
        BoardDocument document = new BoardDocument();
        document.setBoardId(board.getBoardId());
        document.setMemberId(board.getMemberId());
        document.setBoardTitle(board.getBoardTitle());
        document.setBoardContent(board.getBoardContent());
        document.setCategoryIdx(board.getCategoryIdx());
        document.setViewCount(board.getViewCount());
        document.setNoticeYn(board.getNoticeYn());
        document.setRegDate(board.getRegDate());
        document.setModDate(board.getModDate());
        document.setMemberName(board.getMemberName());

        return document;
    }

    public BoardVO toBoardVO() {
        BoardVO board = new BoardVO();
        board.setBoardId(boardId);
        board.setMemberId(memberId);
        board.setBoardTitle(boardTitle);
        board.setBoardContent(boardContent);
        board.setCategoryIdx(categoryIdx);
        board.setViewCount(viewCount);
        board.setNoticeYn(noticeYn);
        board.setRegDate(regDate);
        board.setModDate(modDate);
        board.setMemberName(memberName);

        return board;
    }

    public String getMemberName() {
        return memberName;
    }
    public void setMemberName(String memberName) {
        this.memberName = memberName;
    }
    public int getBoardId() {
        return boardId;
    }
    public void setBoardId(int boardId) {
        this.boardId = boardId;
    }
    public int getMemberId() {
        return memberId;
    }
    public void setMemberId(int memberId) {
        this.memberId = memberId;
    }
    public String getBoardTitle() {
        return boardTitle;
    }
    public void setBoardTitle(String boardTitle) {
        this.boardTitle = boardTitle;
    }
    public String getBoardContent() {
        return boardContent;
    }
    public void setBoardContent(String boardContent) {
        this.boardContent = boardContent;
    }
    public String getCategoryIdx() {
        return categoryIdx;
    }
    public void setCategoryIdx(String categoryIdx) {
        this.categoryIdx = categoryIdx;
    }
    public int getViewCount() {
        return viewCount;
    }
    public void setViewCount(int viewCount) {
        this.viewCount = viewCount;
    }
    public String getNoticeYn() {
        return noticeYn;
    }
    public void setNoticeYn(String noticeYn) {
        this.noticeYn = noticeYn;
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
    @JsonIgnore
    public String getFormattedRegDate() {
        if (regDate == null) return "";
        return regDate.format(DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm"));
    }
    @JsonIgnore
    public String getFormattedModDate() {
        if (modDate == null) return "";
        return modDate.format(DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm"));
    }
}
