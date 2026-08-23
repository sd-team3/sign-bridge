package com.soldesk.dto;

import java.util.List;

import com.soldesk.vo.LandmarkDto;

/** 게임 중 자모 프레임 전송 요청. /api/sign/frame 의 FrameRequest 와 동일한 랜드마크 포맷을 그대로 사용한다. */
public class ChainFrameRequest {
    private List<LandmarkDto> landmarks;
    private boolean mirror;

    public List<LandmarkDto> getLandmarks() { return landmarks; }
    public void setLandmarks(List<LandmarkDto> landmarks) { this.landmarks = landmarks; }

    public boolean isMirror() { return mirror; }
    public void setMirror(boolean mirror) { this.mirror = mirror; }
}
