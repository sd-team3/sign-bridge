package com.soldesk.vo;

import java.util.List;

/** 브라우저가 0.15초 간격으로 이 엔드포인트에 던지는 요청 본문. */
public class FrameRequest {
    private List<LandmarkDto> landmarks;
    private boolean mirror;
    private String clientSessionId; // 브라우저 로컬스토리지에서 발급/유지하는 세션 식별자 (recognition_confirm_log 기록용)
    private Long memberId;          // 브라우저가 /notification/me로 미리 받아와서 실어보내는 값 (비로그인이면 null)

    public List<LandmarkDto> getLandmarks() { return landmarks; }
    public void setLandmarks(List<LandmarkDto> landmarks) { this.landmarks = landmarks; }

    public boolean isMirror() { return mirror; }
    public void setMirror(boolean mirror) { this.mirror = mirror; }

    public String getClientSessionId() { return clientSessionId; }
    public void setClientSessionId(String clientSessionId) { this.clientSessionId = clientSessionId; }

    public Long getMemberId() { return memberId; }
    public void setMemberId(Long memberId) { this.memberId = memberId; }
}
