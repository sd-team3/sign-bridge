package com.soldesk.vo;

public class ChoseongProgressVO {
    private String choseong;
    private int totalCount;
    private int learnedCount;

    public String getChoseong() {
        return choseong;
    }
    public void setChoseong(String choseong) {
        this.choseong = choseong;
    }
    public int getTotalCount() {
        return totalCount;
    }
    public void setTotalCount(int totalCount) {
        this.totalCount = totalCount;
    }
    public int getLearnedCount() {
        return learnedCount;
    }
    public void setLearnedCount(int learnedCount) {
        this.learnedCount = learnedCount;
    }
    public int getPercentage() {
        if (totalCount == 0) return 0;
        return (int) Math.round(learnedCount * 100.0 / totalCount);
    }
}