package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.WrongAnswerVO;

public interface WrongAnswerMapper {
    List<WrongAnswerVO> findWrongAnswersByMemberId(
        @Param("memberId") int memberId, 
        @Param("category") String category, 
        @Param("offset") int offset, 
        @Param("limit") int limit);
    
    int countWrongAnswersByMemberId(@Param("memberId") int memberId, @Param("category") String category);
    
}
