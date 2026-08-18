package com.soldesk.vo;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class JamoHistoryVO {
    private Integer recognitionConfirmLogId;
    private Integer jamoId;
    private String jamoChar;
    private String jamoName;
    private String jamoType;
    private BigDecimal confidence;
    private LocalDateTime regDate;

    public Integer getRecognitionConfirmLogId() {
        return recognitionConfirmLogId;
    }
    public void setRecognitionConfirmLogId(Integer recognitionConfirmLogId) {
        this.recognitionConfirmLogId = recognitionConfirmLogId;
    }
    public Integer getJamoId() {
        return jamoId;
    }
    public void setJamoId(Integer jamoId) {
        this.jamoId = jamoId;
    }
    public String getJamoChar() {
        return jamoChar;
    }
    public void setJamoChar(String jamoChar) {
        this.jamoChar = jamoChar;
    }
    public String getJamoName() {
        return jamoName;
    }
    public void setJamoName(String jamoName) {
        this.jamoName = jamoName;
    }
    public String getJamoType() {
        return jamoType;
    }
    public void setJamoType(String jamoType) {
        this.jamoType = jamoType;
    }
    public BigDecimal getConfidence() {
        return confidence;
    }
    public void setConfidence(BigDecimal confidence) {
        this.confidence = confidence;
    }
    public LocalDateTime getRegDate() {
        return regDate;
    }
    public void setRegDate(LocalDateTime regDate) {
        this.regDate = regDate;
    }
}