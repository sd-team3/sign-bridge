package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.CommentVO;

public interface CommentMapper {
    void insertComment(CommentVO comment);
    List<CommentVO> selectComments(int boardId);
    void updateComment(CommentVO comment);
    int countActiveReplies(int commentId);
    void hardDeleteComment(int commentId);
    void hardDeleteAllRepliesOf(int commentId);
    void softDeleteComment(int commentId);
    void deleteAllRepliesByBoardId(int boardId);
    void deleteAllRootCommentsByBoardId(int boardId);
    int countComment();
    CommentVO selectById(int commentId);
    List<CommentVO> findComments(@Param("start") int start, @Param("count") int count);

    void nullifyMemberId(int memberId);
}
