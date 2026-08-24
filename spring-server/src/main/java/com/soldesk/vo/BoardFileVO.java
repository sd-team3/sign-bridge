package com.soldesk.vo;

import java.time.LocalDateTime;

public class BoardFileVO {
    private int boardFileId;
    private Integer boardId;
    private String origName;
    private String savedName;
    private String filePath;
    private String fileType; // IMAGE / VIDEO
    private Long fileSize;
    private LocalDateTime regDate;

    public int getBoardFileId() {
        return boardFileId;
    }
    public void setBoardFileId(int boardFileId) {
        this.boardFileId = boardFileId;
    }
    public Integer getBoardId() {
        return boardId;
    }
    public void setBoardId(Integer boardId) {
        this.boardId = boardId;
    }
    public String getOrigName() {
        return origName;
    }
    public void setOrigName(String origName) {
        this.origName = origName;
    }
    public String getSavedName() {
        return savedName;
    }
    public void setSavedName(String savedName) {
        this.savedName = savedName;
    }
    public String getFilePath() {
        return filePath;
    }
    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }
    public String getFileType() {
        return fileType;
    }
    public void setFileType(String fileType) {
        this.fileType = fileType;
    }
    public Long getFileSize() {
        return fileSize;
    }
    public void setFileSize(Long fileSize) {
        this.fileSize = fileSize;
    }
    public LocalDateTime getRegDate() {
        return regDate;
    }
    public void setRegDate(LocalDateTime regDate) {
        this.regDate = regDate;
    }
}
