package com.soldesk.vo;

public class SignWordVO {

    private Long signWordId;
    private String signWordName;
    private String choseong;
    private String signWordVideo;
    private String signWordThumbnail;
    private String description;
    private String meaning;
    private String signWordApiId;
    private Integer viewCount;

    public SignWordVO() {
    }

    public Long getSignWordId() {
        return signWordId;
    }

    public void setSignWordId(Long signWordId) {
        this.signWordId = signWordId;
    }

    public String getSignWordName() {
        return signWordName;
    }

    public void setSignWordName(String signWordName) {
        this.signWordName = signWordName;
    }

    public String getChoseong() {
        return choseong;
    }

    public void setChoseong(String choseong) {
        this.choseong = choseong;
    }

    public String getSignWordVideo() {
        return signWordVideo;
    }

    public void setSignWordVideo(String signWordVideo) {
        this.signWordVideo = signWordVideo;
    }

    public String getSignWordThumbnail() {
        return signWordThumbnail;
    }

    public void setSignWordThumbnail(String signWordThumbnail) {
        this.signWordThumbnail = signWordThumbnail;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMeaning() {
        return meaning;
    }

    public void setMeaning(String meaning) {
        this.meaning = meaning;
    }

    public String getSignWordApiId() {
        return signWordApiId;
    }

    public void setSignWordApiId(String signWordApiId) {
        this.signWordApiId = signWordApiId;
    }

    public Integer getViewCount() {
        return viewCount;
    }

    public void setViewCount(Integer viewCount) {
        this.viewCount = viewCount;
    }

    @Override
    public String toString() {
        return "SignWordVO [signWordId=" + signWordId + ", signWordName=" + signWordName
                + ", choseong=" + choseong + ", signWordVideo=" + signWordVideo
                + ", signWordThumbnail=" + signWordThumbnail + ", description=" + description
                + ", signWordApiId=" + signWordApiId + ", viewCount=" + viewCount + "]";
    }
}