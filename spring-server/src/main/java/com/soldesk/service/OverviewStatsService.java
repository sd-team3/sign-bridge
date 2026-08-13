package com.soldesk.service;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.OverviewStatsMapper;
import com.soldesk.vo.ChoseongProgressVO;
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
        vo.setChoseongProgress(overviewStatsMapper.findChoseongProgress(memberId));
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

    private static final Set<String> CHO_GROUP1 = new HashSet<>(Arrays.asList("ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ"));
    private static final Set<String> CHO_GROUP2 = new HashSet<>(Arrays.asList("ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"));

    private List<String> calcBadges(OverviewStatsVO vo) {
        List<String> badges = new ArrayList<>();
        if (vo.getLearnedWordCount() != null && vo.getLearnedWordCount() >= 1) badges.add("first_step");
        if (vo.getStreakDays() != null && vo.getStreakDays() >= 7) badges.add("streak7");
        if (vo.getLearnedWordCount() != null && vo.getLearnedWordCount() >= 50) badges.add("word_master");
        if (vo.getStreakDays() != null && vo.getStreakDays() >= 30) badges.add("streak30");

        List<ChoseongProgressVO> progress = vo.getChoseongProgress();
        if (progress != null && !progress.isEmpty()) {
            Map<String, Integer> pctMap = new HashMap<>();
            for (ChoseongProgressVO p : progress) {
                pctMap.put(p.getChoseong(), p.getPercentage());
            }

            boolean group1Done = isGroupComplete(pctMap, CHO_GROUP1);
            boolean group2Done = isGroupComplete(pctMap, CHO_GROUP2);
            boolean allDone = group1Done && group2Done;

            if (group1Done) badges.add("greeting_master");
            if (group2Done) badges.add("food_master");
            if (allDone) badges.add("complete_all");
        }

        // 올스타: 위에서 계산된 뱃지가 7개(올스타 자기 자신 제외 전부) 다 모이면 획득
        if (badges.size() >= 7) badges.add("allstar");
        
        return badges;
    }

    private boolean isGroupComplete(Map<String, Integer> pctMap, Set<String> group) {
        for (String cho : group) {
            Integer pct = pctMap.get(cho);
            if (pct == null || pct < 100) return false;
        }
        return true;
    }
}