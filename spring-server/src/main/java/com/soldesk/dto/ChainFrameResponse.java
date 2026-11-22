package com.soldesk.dto;


public class ChainFrameResponse {
    private String rawLabel;
    private double rawConfidence;
    private double holdProgress;
    private String confirmedChar;
    private String composedText;
    private long remainingMillis;

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
