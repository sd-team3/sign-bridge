package com.soldesk.mapper;

import java.time.LocalDate;
import java.util.List;

import org.apache.ibatis.annotations.Param;

public interface OverviewStatsMapper {
    Integer countLearnedWords(Integer memberId);
    Integer findAvgAccuracy(Integer memberId);
    List<String> findRecentWords(@Param("memberId") Integer memberId, @Param("limit") int limit);
    List<LocalDate> findActivityDates(Integer memberId);
}