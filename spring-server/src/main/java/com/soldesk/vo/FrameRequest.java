package com.soldesk.vo;

import java.util.List;


public class FrameRequest {
    private List<LandmarkDto> landmarks;
    private boolean mirror;
    private String clientSessionId;
    private Long memberId;

    public List<LandmarkDto> getLandmarks() { return landmarks; }
    public void setLandmarks(List<LandmarkDto> landmarks) { this.landmarks = landmarks; }

    public boolean isMirror() { return mirror; }
    public void setMirror(boolean mirror) { this.mirror = mirror; }

    public String getClientSessionId() { return clientSessionId; }
    public void setClientSessionId(String clientSessionId) { this.clientSessionId = clientSessionId; }

    public Long getMemberId() { return memberId; }
    public void setMemberId(Long memberId) { this.memberId = memberId; }
}
