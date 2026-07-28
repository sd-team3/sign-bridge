package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.BoardVO;

public interface BoardMapper {
    public List<BoardVO> findByCategory(
        @Param("category") String category, @Param("start") int start, @Param("count") int count);
    public int countByCategoryBoard(String category);
    
}
