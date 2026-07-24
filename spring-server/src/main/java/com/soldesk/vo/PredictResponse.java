package com.soldesk.vo;

import java.util.List;

public class PredictResponse {
    private String label;
    private double confidence;
    private List<TopPredictionDto> top3;

    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }

    public double getConfidence() { return confidence; }
    public void setConfidence(double confidence) { this.confidence = confidence; }

    public List<TopPredictionDto> getTop3() { return top3; }
    public void setTop3(List<TopPredictionDto> top3) { this.top3 = top3; }

    public static class TopPredictionDto {
        private String label;
        private double confidence;

        public String getLabel() { return label; }
        public void setLabel(String label) { this.label = label; }

        public double getConfidence() { return confidence; }
        public void setConfidence(double confidence) { this.confidence = confidence; }
    }
}
