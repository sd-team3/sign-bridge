package com.soldesk.vo;

import java.time.LocalDateTime;

/** recognition_confirm_log 테이블 1:1 매핑. 자모 하나가 확정될 때마다 한 행씩 쌓인다. */
public class RecognitionConfirmLogVO {

    private Long recognitionConfirmLogId;
    private String clientSessionId;
    private Long memberId;          // 비로그인이면 null
    private String confirmedChar;
    private double confidence;
    private int holdDurationMs;
    private String landmarkJson;    // 확정 시점 랜드마크 21개 좌표를 JSON 문자열로 직렬화해서 저장
    private LocalDateTime regDate;  // INSERT 시 DB의 DEFAULT CURRENT_TIMESTAMP가 채움, 조회용

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
