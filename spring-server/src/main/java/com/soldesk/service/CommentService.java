package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.BoardMapper;
import com.soldesk.mapper.CommentMapper;
import com.soldesk.vo.CommentVO;

@Service
public class CommentService {
    @Autowired
    private CommentMapper commentMapper;
    @Autowired
    private BoardMapper boardMapper;
    

    @Transactional
    public void insertComment(CommentVO comment) {
        CommentVO parent = commentMapper.selectById(comment.getParentCommentId());
        if(parent != null) comment.setParentCommentId(parent.getCommentId());
        commentMapper.insertComment(comment);
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
        commentMapper.deleteComment(commentId);
    }
    @Transactional
    public List<CommentVO> getAllComments(int page, int count) {
        int start = (page - 1) * count;
        return commentMapper.findComments(start, count);
    }
    @Transactional
    public void deleteCommentByBoardId(int boardId) {
        commentMapper.deleteCommentByBoardId(boardId);
    }
}
