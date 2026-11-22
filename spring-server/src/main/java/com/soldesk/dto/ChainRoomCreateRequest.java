package com.soldesk.dto;


public class ChainRoomCreateRequest {
    private String chainRoomName;
    private Integer chainRoomCapacity;

    public String getChainRoomName() { return chainRoomName; }
    public void setChainRoomName(String chainRoomName) { this.chainRoomName = chainRoomName; }

    public Integer getChainRoomCapacity() { return chainRoomCapacity; }
    public void setChainRoomCapacity(Integer chainRoomCapacity) { this.chainRoomCapacity = chainRoomCapacity; }
}
