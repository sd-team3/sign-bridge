package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.CommentVO;

public interface CommentMapper {
    void insertComment(CommentVO comment);
    List<CommentVO> selectComments(int boardId);
    void updateComment(CommentVO comment);
    void deleteComment(int commentId);
    void deleteCommentByBoardId(int boardId);
    int countComment();
    CommentVO selectById(int commentId);
    List<CommentVO> findComments(@Param("start") int start, @Param("count") int count);
}
