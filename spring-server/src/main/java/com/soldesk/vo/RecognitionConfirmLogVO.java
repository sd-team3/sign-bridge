package com.soldesk.vo;

import java.time.LocalDateTime;


public class RecognitionConfirmLogVO {

    private Long recognitionConfirmLogId;
    private String clientSessionId;
    private Long memberId;
    private String confirmedChar;
    private double confidence;
    private int holdDurationMs;
    private String landmarkJson;
    private LocalDateTime regDate;

    public Long getRecognitionConfirmLogId() { return recognitionConfirmLogId; }
    public void setRecognitionConfirmLogId(Long recognitionConfirmLogId) { this.recognitionConfirmLogId = recognitionConfirmLogId; }

    public String getClientSessionId() { return clientSessionId; }
    public void setClientSessionId(String clientSessionId) { this.clientSessionId = clientSessionId; }

    public Long getMemberId() { return memberId; }
    public void setMemberId(Long memberId) { this.memberId = memberId; }

    public String getConfirmedChar() { return confirmedChar; }
    public void setConfirmedChar(String confirmedChar) { this.confirmedChar = confirmedChar; }

    public double getConfidence() { return confidence; }
    public void setConfidence(double confidence) { this.confidence = confidence; }

    public int getHoldDurationMs() { return holdDurationMs; }
    public void setHoldDurationMs(int holdDurationMs) { this.holdDurationMs = holdDurationMs; }

    public String getLandmarkJson() { return landmarkJson; }
    public void setLandmarkJson(String landmarkJson) { this.landmarkJson = landmarkJson; }

    public LocalDateTime getRegDate() { return regDate; }
    public void setRegDate(LocalDateTime regDate) { this.regDate = regDate; }
}
