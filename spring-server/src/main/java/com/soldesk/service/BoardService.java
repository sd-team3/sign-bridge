package com.soldesk.service;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.BoardMapper;
import com.soldesk.vo.BoardVO;

@Service
public class BoardService {
    
    @Autowired
    private BoardMapper boardMapper;
    @Autowired
    private BoardSearchService boardSearchService;

    @Transactional
    public List<BoardVO> getBoardByCategory(String category, int page, int count) {
        int start = (page - 1) * count;
        List<BoardVO> list = boardMapper.findByCategory(category, start, count);
        return list;
    }
    @Transactional
    public int getCategoryBoardCount(String category) {
        return boardMapper.countByCategoryBoard(category);
    }
    @Transactional
    public Map<String, Object> getBoardState() {
        return boardMapper.getBoardStats();
    }

    @Transactional
    public void writeBoard(BoardVO board) {
        boardMapper.insertBoard(board);
        BoardVO indexBoard = boardMapper.selectBoardByBoardId(board.getBoardId());
        boardSearchService.indexBoard(indexBoard);
    }
    
    @Transactional
    public BoardVO getBoardByBoardId(int boardId) {
        return boardMapper.selectBoardByBoardId(boardId);
    }

    @Transactional
    public void increaseViewCount(int boardId) {
        boardMapper.increaseViewCount(boardId);
    }
    
    @Transactional
    public void updateBoard(BoardVO board) {
        boardMapper.updateBoard(board);
        BoardVO indexBoard = boardMapper.selectBoardByBoardId(board.getBoardId());
        boardSearchService.indexBoard(indexBoard);
    }

    @Transactional
    public void deleteBoard(int boardId) {
        boardMapper.deleteBoard(boardId);
    }

    @Transactional
    public void anonymizeMemberBoards(int memberId) {
        boardMapper.nullifyMemberId(memberId);
    }
}
