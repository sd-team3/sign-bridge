package com.soldesk.vo;

/** 프레임 처리 결과. 브라우저는 이걸로 진행률 표시 / 확정 글자 애니메이션 / 최종 문장을 그린다. */
public class FrameResponse {
    private String rawLabel;          // 이번 프레임에서 Python이 예측한 raw 라벨 (유지 판정 전)
    private double rawConfidence;     // 그 확신도
    private double holdProgress;      // 0.0~1.0, 1.2초 유지까지 얼마나 왔는지 (프론트에서 진행바로 표시하기 좋음)
    private String confirmedChar;     // 이번 호출에서 막 1.2초 유지 완료되어 확정된 글자 (없으면 null)
    private String composedText;      // 지금까지 조합된 전체 텍스트 (조합 중인 음절 미리보기 포함)

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
}
