package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.JamoHistoryVO;
import com.soldesk.vo.WordHistoryVO;

public interface LearningHistoryMapper {
    int countJamoHistoryByMemberId(@Param("memberId") int memberId, @Param("category") String category);
    List<JamoHistoryVO> findJamoHistoryByMemberId(
        @Param("memberId") int memberId, @Param("category") String category, 
        @Param("start") int start, @Param("limit") int limit);
    int countWordHistoryByMemberId(@Param("memberId") int memberId, @Param("category") String category);
    List<WordHistoryVO> findWordHistoryByMemberId(
        @Param("memberId") int memberId, @Param("category") String category, 
        @Param("start") int start, @Param("limit") int limit);
}
