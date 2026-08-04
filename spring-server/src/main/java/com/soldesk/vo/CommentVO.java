package com.soldesk.vo;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class CommentVO {
   private int commentId;
   private String commentContent;
   private int boardId;
   private Integer memberId;
   private Integer parentCommentId;
   private LocalDateTime regDate;
   private String delYn; 

   private String memberName;

   private String boardTitle;

   // 자식 댓글 개수 저장용
   private String replyCnt;

   public String getReplyCnt() {
    return replyCnt;
}
   public void setReplyCnt(String replyCnt) {
    this.replyCnt = replyCnt;
   }
   public String getBoardTitle() {
    return boardTitle;
    }
   public void setBoardTitle(String boardTitle) {
    this.boardTitle = boardTitle;
   }
   public int getCommentId() {
    return commentId;
   }
   public void setCommentId(int commentId) {
    this.commentId = commentId;
   }
   public String getCommentContent() {
    return commentContent;
   }
   public void setCommentContent(String commentContent) {
    this.commentContent = commentContent;
   }
   public int getBoardId() {
    return boardId;
   }
   public void setBoardId(int boardId) {
    this.boardId = boardId;
   }
   public Integer getMemberId() {
    return memberId;
   }
   public void setMemberId(Integer memberId) {
    this.memberId = memberId;
   }
   public Integer getParentCommentId() {
    return parentCommentId;
   }
   public void setParentCommentId(int parentCommentId) {
    this.parentCommentId = parentCommentId;
   }
   public LocalDateTime getRegDate() {
    return regDate;
   }
   public void setRegDate(LocalDateTime regDate) {
    this.regDate = regDate;
   }
   public String getMemberName() {
    return memberName;
   }
   public void setMemberName(String memberName) {
    this.memberName = memberName;
   }
    public String getFormattedRegDate() {
        if (regDate == null) return "";
        return regDate.format(DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm"));
    }
    public void setDelYn(String delYn) {
        this.delYn = delYn;
    }
    public String getDelYn() {
        return delYn;
    }
}
