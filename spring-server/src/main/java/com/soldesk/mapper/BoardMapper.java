package com.soldesk.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.BoardVO;

public interface BoardMapper {
    List<BoardVO> findByCategory(
        @Param("category") String category, @Param("start") int start, @Param("count") int count);
    int countByCategoryBoard(String category);
    void insertBoard(BoardVO board);
    BoardVO selectBoardByBoardId(int boardId);
    Map<String, Object> getBoardStats();
    void increaseViewCount(int boardId);
    void updateBoard(BoardVO board);
    void deleteBoard(int boardId);
    
    List<BoardVO> findAllForIndex();
    
    void nullifyMemberId(int memberId);

    List<BoardVO> findByMemberId(@Param("memberId") int memberId, @Param("category") String category, @Param("start") int offset, @Param("limit") int limit);
    int countByMemberId(@Param("memberId") int memberId, @Param("category") String category);

    // 오늘 추가된 게시판 개수
    int countTodayBoard();

    List<BoardVO> boardByMemberId(int memberId);

    
}
