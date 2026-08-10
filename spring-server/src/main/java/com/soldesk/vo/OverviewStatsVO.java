package com.soldesk.vo;

import java.util.List;

public class OverviewStatsVO {
    private Integer learnedWordCount;
    private Integer avgAccuracy;
    private Integer streakDays;
    private List<String> recentWords;
    private List<String> earnedBadges;
    private String earnedBadgesCsv;
    private List<ChoseongProgressVO> choseongProgress;

    public List<ChoseongProgressVO> getChoseongProgress() { 
        return choseongProgress; 
    }
    public void setChoseongProgress(List<ChoseongProgressVO> choseongProgress) { 
        this.choseongProgress = choseongProgress;
    }
    public String getEarnedBadgesCsv() {
        return earnedBadgesCsv;
    }
    public void setEarnedBadgesCsv(String earnedBadgesCsv) {
        this.earnedBadgesCsv = earnedBadgesCsv;
    }
    public List<String> getEarnedBadges() {
        return earnedBadges;
    }
    public void setEarnedBadges(List<String> earnedBadges) {
        this.earnedBadges = earnedBadges;
    }
    public Integer getLearnedWordCount() {
        return learnedWordCount; 
    }
    public void setLearnedWordCount(Integer learnedWordCount) {
        this.learnedWordCount = learnedWordCount; 
    }
    public Integer getAvgAccuracy() {
        return avgAccuracy; 
    }
    public void setAvgAccuracy(Integer avgAccuracy) {
        this.avgAccuracy = avgAccuracy; 
    }
    public Integer getStreakDays() {
        return streakDays;
    }
    public void setStreakDays(Integer streakDays) {
        this.streakDays = streakDays; 
    }
    public List<String> getRecentWords() { 
        return recentWords; 
    }
    public void setRecentWords(List<String> recentWords) { 
        this.recentWords = recentWords; 
    }
}