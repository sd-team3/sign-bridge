package com.soldesk.vo;

import java.time.LocalDateTime;

/** chain_room 테이블 매핑. 끝말잇기 게임방. */
public class ChainRoomVO {

    // 방 상태값 (status 컬럼)
    public static final String STATUS_WAITING = "WAITING";
    public static final String STATUS_PLAYING = "PLAYING";
    public static final String STATUS_ENDED = "ENDED";

    private Long chainRoomId;
    private String chainRoomName;
    private String status;
    private Integer chainRoomCapacity;
    private Integer turnTimeLimitBaseSec;
    private Integer hostMemberId;
    private Integer currentTurnMemberId;
    private LocalDateTime currentTurnDeadline;
    private Long lastChainWordId;
    private Integer winnerMemberId;
    private LocalDateTime regDate;
    private LocalDateTime startedDate;
    private LocalDateTime endedDate;

    public Long getChainRoomId() { return chainRoomId; }
    public void setChainRoomId(Long chainRoomId) { this.chainRoomId = chainRoomId; }

    public String getChainRoomName() { return chainRoomName; }
    public void setChainRoomName(String chainRoomName) { this.chainRoomName = chainRoomName; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getChainRoomCapacity() { return chainRoomCapacity; }
    public void setChainRoomCapacity(Integer chainRoomCapacity) { this.chainRoomCapacity = chainRoomCapacity; }

    public Integer getTurnTimeLimitBaseSec() { return turnTimeLimitBaseSec; }
    public void setTurnTimeLimitBaseSec(Integer turnTimeLimitBaseSec) { this.turnTimeLimitBaseSec = turnTimeLimitBaseSec; }

    public Integer getHostMemberId() { return hostMemberId; }
    public void setHostMemberId(Integer hostMemberId) { this.hostMemberId = hostMemberId; }

    public Integer getCurrentTurnMemberId() { return currentTurnMemberId; }
    public void setCurrentTurnMemberId(Integer currentTurnMemberId) { this.currentTurnMemberId = currentTurnMemberId; }

    public LocalDateTime getCurrentTurnDeadline() { return currentTurnDeadline; }
    public void setCurrentTurnDeadline(LocalDateTime currentTurnDeadline) { this.currentTurnDeadline = currentTurnDeadline; }

    public Long getLastChainWordId() { return lastChainWordId; }
    public void setLastChainWordId(Long lastChainWordId) { this.lastChainWordId = lastChainWordId; }

    public Integer getWinnerMemberId() { return winnerMemberId; }
    public void setWinnerMemberId(Integer winnerMemberId) { this.winnerMemberId = winnerMemberId; }

    public LocalDateTime getRegDate() { return regDate; }
    public void setRegDate(LocalDateTime regDate) { this.regDate = regDate; }

    public LocalDateTime getStartedDate() { return startedDate; }
    public void setStartedDate(LocalDateTime startedDate) { this.startedDate = startedDate; }

    public LocalDateTime getEndedDate() { return endedDate; }
    public void setEndedDate(LocalDateTime endedDate) { this.endedDate = endedDate; }
}
