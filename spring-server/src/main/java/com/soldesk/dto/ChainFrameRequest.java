package com.soldesk.dto;

import java.util.List;

import com.soldesk.vo.LandmarkDto;


public class ChainFrameRequest {
    private List<LandmarkDto> landmarks;
    private boolean mirror;

    public List<LandmarkDto> getLandmarks() { return landmarks; }
    public void setLandmarks(List<LandmarkDto> landmarks) { this.landmarks = landmarks; }

    public boolean isMirror() { return mirror; }
    public void setMirror(boolean mirror) { this.mirror = mirror; }
}
