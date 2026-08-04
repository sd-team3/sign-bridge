package com.soldesk.vo;

import java.util.List;

/** 브라우저가 0.15초 간격으로 이 엔드포인트에 던지는 요청 본문. */
public class FrameRequest {
    private List<LandmarkDto> landmarks;
    private boolean mirror;

    public List<LandmarkDto> getLandmarks() { return landmarks; }
    public void setLandmarks(List<LandmarkDto> landmarks) { this.landmarks = landmarks; }

    public boolean isMirror() { return mirror; }
    public void setMirror(boolean mirror) { this.mirror = mirror; }
}
