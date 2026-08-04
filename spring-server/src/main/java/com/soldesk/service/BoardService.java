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

    @Autowired
    private AdminService adminService;

    @Transactional
    public void updateBoard(BoardVO board) {
        boardMapper.updateBoard(board);
        BoardVO indexBoard = boardMapper.selectBoardByBoardId(board.getBoardId());
        boardSearchService.indexBoard(indexBoard);

        // 오류신고 게시글이면 연결된 inquiry 내용도 같이 갱신
        if ("REPORT".equals(board.getCategoryIdx())) {
            adminService.syncInquiryContentByBoard(board.getBoardId(), board.getBoardContent());
        }
    }

    @Transactional
    public int getCategoryBoardCount(String category) {
        return boardMapper.countByCategoryBoard(category);
    }

    @Transactional
    public List<BoardVO> getBoardByCategory(String category, int page, int count) {
        int start = (page - 1) * count; // 페이지 번호를 offset으로 변환
        return boardMapper.findByCategory(category, start, count);
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
    public void deleteBoard(int boardId) {
        boardMapper.deleteBoard(boardId);
    }
}
