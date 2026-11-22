package com.soldesk.vo;

public class PageBean {

    private int currentPage;
    private int totalCnt;
    private int pageCnt;
    private int min;
    private int max;
    private int prevPage;
    private int nextPage;
    private int totalPageCnt;


    public PageBean(int currentPage, int totalCnt, int pageCnt) {
        if (pageCnt <= 0) pageCnt = 10;

        this.totalCnt = totalCnt;
        this.pageCnt = pageCnt;

        totalPageCnt = totalCnt / pageCnt;
        if (totalCnt % pageCnt != 0) totalPageCnt += 1;
        if (totalPageCnt < 1) totalPageCnt = 1;

        if (currentPage < 1) currentPage = 1;
        if (currentPage > totalPageCnt) currentPage = totalPageCnt;
        this.currentPage = currentPage;

        min = ((currentPage - 1) / 10) * 10 + 1;
        max = min + 10 - 1;
        if (max > totalPageCnt) max = totalPageCnt;

        prevPage = (min == 1) ? 1 : min - 1;
        nextPage = (max == totalPageCnt) ? totalPageCnt : max + 1;
    }

    public int getCurrentPage() {
        return currentPage;
    }
    public void setCurrentPage(int currentPage) {
        this.currentPage = currentPage;
    }
    public int getTotalCnt() {
        return totalCnt;
    }
    public void setTotalCnt(int contentCnt) {
        this.totalCnt = contentCnt;
    }
    public int getPageCnt() {
        return pageCnt;
    }
    public void setPageCnt(int contentPageCnt) {
        this.pageCnt = contentPageCnt;
    }
    public int getMin() {
        return min;
    }
    public void setMin(int min) {
        this.min = min;
    }
    public int getMax() {
        return max;
    }
    public void setMax(int max) {
        this.max = max;
    }
    public int getPrevPage() {
        return prevPage;
    }
    public void setPrevPage(int prevPage) {
        this.prevPage = prevPage;
    }
    public int getNextPage() {
        return nextPage;
    }
    public void setNextPage(int nextPage) {
        this.nextPage = nextPage;
    }
    public int getTotalPageCnt() {
        return totalPageCnt;
    }
    public void setTotalPageCnt(int pageCnt) {
        this.totalPageCnt = pageCnt;
    }

}

