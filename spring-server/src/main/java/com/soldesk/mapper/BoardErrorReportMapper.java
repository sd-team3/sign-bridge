package com.soldesk.mapper;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.BoardErrorReportVO;

public interface BoardErrorReportMapper {
    void insert(@Param("boardId") int boardId, @Param("errorType") String errorType, @Param("relatedWord") String relatedWord);
    BoardErrorReportVO findByBoardId(int boardId);
}
