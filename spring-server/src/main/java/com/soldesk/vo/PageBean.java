package com.soldesk.vo;

public class PageBean {

    private int currentPage; // 현재 페이지 번호
    private int totalCnt; // 전체 개수
    private int pageCnt; // 페이지당 개수
    private int min; // 최소페이지 번호
    private int max; // 최대페이지 번호
    private int prevPage; // 이전 버튼 페이지 번호
    private int nextPage; // 다음 바튼 페이지 번호
    private int totalPageCnt; // 전체 페이지 개수

    // 현재 페이지 정보, 전체 개수, 페이지당 글의 개수, 
    public PageBean(int currentPage, int totalCnt, int pageCnt) {
        if (pageCnt <= 0) pageCnt = 10; // 방어: 0 이하 방지

        this.totalCnt = totalCnt;
        this.pageCnt = pageCnt;

        totalPageCnt = totalCnt / pageCnt;
        if (totalCnt % pageCnt != 0) totalPageCnt += 1;
        if (totalPageCnt < 1) totalPageCnt = 1; // 0개여도 1페이지는 있는 걸로 처리

        if (currentPage < 1) currentPage = 1;           // 방어: 0 이하 방지
        if (currentPage > totalPageCnt) currentPage = totalPageCnt; // 방어: 범위 초과 방지
        this.currentPage = currentPage;

        min = ((currentPage - 1) / 10) * 10 + 1;
        max = min + 10 - 1;
        if (max > totalPageCnt) max = totalPageCnt;

        prevPage = (min == 1) ? 1 : min - 1;  // min이 1이면 더 이전 없음 → 1로 고정
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

