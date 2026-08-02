package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.CommentMapper;
import com.soldesk.vo.CommentVO;

@Service
public class CommentService {
    @Autowired
    private CommentMapper commentMapper;
    
    @Transactional
    public void insertComment(CommentVO comment) {
        if(comment.getParentCommentId() != null) {
            CommentVO parent = commentMapper.selectById(comment.getParentCommentId());
            if(parent != null && parent.getParentCommentId() != null) {
                comment.setParentCommentId(parent.getCommentId());
            } 
        }
        commentMapper.insertComment(comment);
    }
    @Transactional(readOnly = true)
    public CommentVO getComment(int commentId) {
        return commentMapper.selectById(commentId);
    }
    @Transactional
    public List<CommentVO> getComments(int boardId) {
        List<CommentVO> list = commentMapper.selectComments(boardId);
        return list;
    }
    @Transactional
    public void updateComment(CommentVO comment) {
        commentMapper.updateComment(comment);
    }
    @Transactional
    public void deleteComment(int commentId) {
        CommentVO target = commentMapper.selectById(commentId);
        if (target == null) return;

        if (target.getParentCommentId() == null) {
            int activeReplies = commentMapper.countActiveReplies(commentId);
            if (activeReplies == 0) {
                commentMapper.hardDeleteAllRepliesOf(commentId);
                commentMapper.hardDeleteComment(commentId);
            } else {
                commentMapper.softDeleteComment(commentId);
            }
        } else {
            commentMapper.hardDeleteComment(commentId);

            int parentId = target.getParentCommentId();
            CommentVO parent = commentMapper.selectById(parentId);
            if (parent != null && "Y".equals(parent.getDelYn())) {
                int remainingActive = commentMapper.countActiveReplies(parentId);
                if (remainingActive == 0) {
                    commentMapper.hardDeleteAllRepliesOf(parentId);
                    commentMapper.hardDeleteComment(parentId);
                }
            }
        }
    }
    @Transactional
    public List<CommentVO> getAllComments(int page, int count) {
        int start = (page - 1) * count;
        return commentMapper.findComments(start, count);
    }
    @Transactional
    public void deleteAllCommentsByBoardId(int boardId) {
        commentMapper.deleteAllRepliesByBoardId(boardId);
        commentMapper.deleteAllRootCommentsByBoardId(boardId);
    }
}
