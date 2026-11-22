package com.soldesk.vo;

import com.soldesk.util.HangulComposer;

import java.util.Objects;





public class RecognitionState {

    private final HangulComposer composer = new HangulComposer();

    private String candidateLabel = null;
    private long candidateStartMillis = 0L;
    private boolean candidateConfirmed = false;

    public HangulComposer getComposer() {
        return composer;
    }


    public void setCandidate(String label, long nowMillis) {
        this.candidateLabel = label;
        this.candidateStartMillis = nowMillis;
        this.candidateConfirmed = false;
    }

    public boolean isSameCandidate(String label) {
        return Objects.equals(this.candidateLabel, label);
    }

    public long getHoldMillis(long nowMillis) {
        if (candidateLabel == null) return 0;
        return nowMillis - candidateStartMillis;
    }

    public boolean isCandidateConfirmed() {
        return candidateConfirmed;
    }

    public void markConfirmed() {
        this.candidateConfirmed = true;
    }
}
