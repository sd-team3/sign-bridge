package com.soldesk.vo;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class CommentVO {
   private int commentId;
   private String commentContent;
   private int boardId;
   private int memberId;
   private int parentCommentId;
   private LocalDateTime regDate;

   private String memberName;

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
   public int getMemberId() {
    return memberId;
   }
   public void setMemberId(int memberId) {
    this.memberId = memberId;
   }
   public int getParentCommentId() {
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
}
