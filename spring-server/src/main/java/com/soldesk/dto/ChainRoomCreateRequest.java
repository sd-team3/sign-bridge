package com.soldesk.dto;

/** 방 생성 요청 바디 */
public class ChainRoomCreateRequest {
    private String chainRoomName;
    private Integer chainRoomCapacity; // 미지정 시 4

    public String getChainRoomName() { return chainRoomName; }
    public void setChainRoomName(String chainRoomName) { this.chainRoomName = chainRoomName; }

    public Integer getChainRoomCapacity() { return chainRoomCapacity; }
    public void setChainRoomCapacity(Integer chainRoomCapacity) { this.chainRoomCapacity = chainRoomCapacity; }
}
