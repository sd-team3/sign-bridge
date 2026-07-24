package com.soldesk.vo;

import com.soldesk.util.HangulComposer;

import java.util.Objects;

/**
 * HttpSession에 하나씩 붙는 인식 상태.
 * "같은 라벨이 얼마나 유지되고 있는지"와 "지금까지 조합된 텍스트"를 함께 들고 있는다.
 */
public class RecognitionState {

    private final HangulComposer composer = new HangulComposer();

    private String candidateLabel = null;
    private long candidateStartMillis = 0L;
    private boolean candidateConfirmed = false; // 이번 유지 구간에서 이미 확정했는지 (중복 확정 방지)

    public HangulComposer getComposer() {
        return composer;
    }

    /** 새로 감지된 라벨로 후보를 교체하거나(라벨이 바뀐 경우), null로 초기화한다(신뢰도 낮은 경우). */
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
