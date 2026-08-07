package com.soldesk.service;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.OverviewStatsMapper;
import com.soldesk.vo.OverviewStatsVO;

@Service
public class OverviewStatsService {

    @Autowired
    private OverviewStatsMapper overviewStatsMapper;

    public OverviewStatsVO getOverviewStats(Integer memberId) {
        OverviewStatsVO vo = new OverviewStatsVO();
        vo.setLearnedWordCount(overviewStatsMapper.countLearnedWords(memberId));
        vo.setAvgAccuracy(overviewStatsMapper.findAvgAccuracy(memberId));
        vo.setRecentWords(overviewStatsMapper.findRecentWords(memberId, 6));
        vo.setStreakDays(calcStreak(overviewStatsMapper.findActivityDates(memberId)));
        vo.setEarnedBadges(calcBadges(vo));
        vo.setEarnedBadgesCsv("," + String.join(",", vo.getEarnedBadges()) + ",");
        return vo;
    }

    private Integer calcStreak(List<LocalDate> activityDatesDesc) {
        if (activityDatesDesc == null || activityDatesDesc.isEmpty()) return 0;
        Set<LocalDate> dateSet = new HashSet<>(activityDatesDesc);
        LocalDate today = LocalDate.now();
        LocalDate cursor = dateSet.contains(today) ? today : today.minusDays(1);
        if (!dateSet.contains(cursor)) return 0;
        int streak = 0;
        while (dateSet.contains(cursor)) {
            streak++;
            cursor = cursor.minusDays(1);
        }
        return streak;
    }

    private List<String> calcBadges(OverviewStatsVO vo) {
        List<String> badges = new ArrayList<>();
        if (vo.getLearnedWordCount() != null && vo.getLearnedWordCount() >= 1) badges.add("first_step");
        if (vo.getStreakDays() != null && vo.getStreakDays() >= 7) badges.add("streak7");
        if (vo.getLearnedWordCount() != null && vo.getLearnedWordCount() >= 50) badges.add("word_master");
        if (vo.getStreakDays() != null && vo.getStreakDays() >= 30) badges.add("streak30");
        return badges;
    }
}