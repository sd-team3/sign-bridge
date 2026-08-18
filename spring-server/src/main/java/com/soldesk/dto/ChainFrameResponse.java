package com.soldesk.dto;

/** 프레임 처리 결과. FrameResponse(/api/sign)와 동일한 필드 + 남은시간(턴 연장 반영) */
public class ChainFrameResponse {
    private String rawLabel;
    private double rawConfidence;
    private double holdProgress;
    private String confirmedChar;
    private String composedText;
    private long remainingMillis; // 자모 확정으로 연장된 후의 남은 턴 시간

    public String getRawLabel() { return rawLabel; }
    public void setRawLabel(String rawLabel) { this.rawLabel = rawLabel; }

    public double getRawConfidence() { return rawConfidence; }
    public void setRawConfidence(double rawConfidence) { this.rawConfidence = rawConfidence; }

    public double getHoldProgress() { return holdProgress; }
    public void setHoldProgress(double holdProgress) { this.holdProgress = holdProgress; }

    public String getConfirmedChar() { return confirmedChar; }
    public void setConfirmedChar(String confirmedChar) { this.confirmedChar = confirmedChar; }

    public String getComposedText() { return composedText; }
    public void setComposedText(String composedText) { this.composedText = composedText; }

    public long getRemainingMillis() { return remainingMillis; }
    public void setRemainingMillis(long remainingMillis) { this.remainingMillis = remainingMillis; }
}
