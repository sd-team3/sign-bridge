package com.soldesk.vo;

import java.time.LocalDateTime;

public class FavoriteWordVO {
    private Integer memberId;
    private Integer signWordId;
    private LocalDateTime regDate;
    private String signWordName;
    private String choseong;
    
    public String getChoseong() {
        return choseong;
    }
    public void setChoseong(String choseong) {
        this.choseong = choseong;
    }
    public Integer getMemberId() {
        return memberId;
    }
    public void setMemberId(Integer memberId) {
        this.memberId = memberId;
    }
    public Integer getSignWordId() {
        return signWordId;
    }
    public void setSignWordId(Integer signWordId) {
        this.signWordId = signWordId;
    }
    public LocalDateTime getRegDate() {
        return regDate;
    }
    public void setRegDate(LocalDateTime regDate) {
        this.regDate = regDate;
    }
    public String getSignWordName() {
        return signWordName;
    }
    public void setSignWordName(String signWordName) {
        this.signWordName = signWordName;
    }
    
}