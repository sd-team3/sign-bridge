package com.soldesk.service;

import java.util.HashMap;
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


    // 게시글 수정 처리
    @Transactional
    public void updateBoard(BoardVO board) {
        boardMapper.updateBoard(board);
        BoardVO indexBoard = boardMapper.selectBoardByBoardId(board.getBoardId());
        boardSearchService.indexBoard(indexBoard);
    }
    // 카테고리별 게시글 갯수 카운트
    @Transactional
    public int getCategoryBoardCount(String category) {
        return boardMapper.countByCategoryBoard(category);
    }
    // 카테고리별 게시글 조회
    @Transactional
    public List<BoardVO> getBoardByCategory(String category, int page, int count) {
        int start = (page - 1) * count; // 페이지 번호를 offset으로 변환
        return boardMapper.findByCategory(category, start, count);
    }
    // 카테고리별 게시글 갯수 카운트 후 map형태로 반환
    @Transactional
    public Map<String, Object> getBoardState() {
        return boardMapper.getBoardStats();
    }
    // 게시글 작성 처리
    @Transactional
    public void writeBoard(BoardVO board) {
        boardMapper.insertBoard(board);
        BoardVO indexBoard = boardMapper.selectBoardByBoardId(board.getBoardId());
        boardSearchService.indexBoard(indexBoard);
    }
    // 게시글 id로 조회
    @Transactional
    public BoardVO getBoardByBoardId(int boardId) {
        return boardMapper.selectBoardByBoardId(boardId);
    }
    // 게시글 조회수 증가
    @Transactional
    public void increaseViewCount(int boardId) {
        boardMapper.increaseViewCount(boardId);
    }
    // 게시글 삭제 처리
    @Transactional
    public void deleteBoard(int boardId) {
        boardMapper.deleteBoard(boardId);
    }
    // 게시글 작성자 null 처리(멤버 삭제 시 게시글은 남겨두기용)
    @Transactional
    public void anonymizeMemberBoards(int memberId) {
        boardMapper.nullifyMemberId(memberId);
    }
    // 멤버가 작성한 게시글 카테고리별 조회해서 map형태 반환
    @Transactional
    public Map<String, Object> getBoardsByMember(int memberId, String category, int page) {
        int pageSize = 10;
        int start = (page - 1) * pageSize;
        List<BoardVO> boards = boardMapper.findByMemberId(memberId, category, start, pageSize);
        int totalCount = boardMapper.countByMemberId(memberId, category);
        Map<String, Object> result = new HashMap<>();
        result.put("boards", boards);
        result.put("totalCount", totalCount);
        result.put("totalPages", (int) Math.ceil((double) totalCount / pageSize));
        result.put("currentPage", page);
        return result;
    }
    // 오늘 추가된 게시글 갯수 카운트
    @Transactional
    public int countTodayBoard() {
        return boardMapper.countTodayBoard();
    }
    // 멤버 id로 게시글 조회
    @Transactional
    public List<BoardVO> boardByMemberId(int memberId) {
        return boardMapper.boardByMemberId(memberId);
    }
}
