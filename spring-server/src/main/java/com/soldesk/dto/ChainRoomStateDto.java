package com.soldesk.dto;

import java.util.List;

public class ChainRoomStateDto {
    private Long chainRoomId;
    private String chainRoomName;
    private String status;
    private Integer chainRoomCapacity;
    private Integer turnTimeLimitBaseSec;
    private Integer hostMemberId;
    private Integer currentTurnMemberId;
    private Long deadlineEpochMillis;
    private String requiredFirstChar;
    private String alternativeFirstChar;
    private Integer winnerMemberId;
    private List<ChainRoomMemberDto> members;

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

    public Long getDeadlineEpochMillis() { return deadlineEpochMillis; }
    public void setDeadlineEpochMillis(Long deadlineEpochMillis) { this.deadlineEpochMillis = deadlineEpochMillis; }

    public String getRequiredFirstChar() { return requiredFirstChar; }
    public void setRequiredFirstChar(String requiredFirstChar) { this.requiredFirstChar = requiredFirstChar; }

    public String getAlternativeFirstChar() { return alternativeFirstChar; }
    public void setAlternativeFirstChar(String alternativeFirstChar) { this.alternativeFirstChar = alternativeFirstChar; }

    public Integer getWinnerMemberId() { return winnerMemberId; }
    public void setWinnerMemberId(Integer winnerMemberId) { this.winnerMemberId = winnerMemberId; }

    public List<ChainRoomMemberDto> getMembers() { return members; }
    public void setMembers(List<ChainRoomMemberDto> members) { this.members = members; }

    public static class ChainRoomMemberDto {
        private Integer memberId;
        private String memberName;
        private String memberProfileImage;
        private Integer turnNo;
        private Integer lives;
        private Integer score;
        private boolean eliminated;
        private Integer finalRank;

        public Integer getMemberId() { return memberId; }
        public void setMemberId(Integer memberId) { this.memberId = memberId; }

        public String getMemberName() { return memberName; }
        public void setMemberName(String memberName) { this.memberName = memberName; }

        public String getMemberProfileImage() { return memberProfileImage; }
        public void setMemberProfileImage(String memberProfileImage) { this.memberProfileImage = memberProfileImage; }

        public Integer getTurnNo() { return turnNo; }
        public void setTurnNo(Integer turnNo) { this.turnNo = turnNo; }

        public Integer getLives() { return lives; }
        public void setLives(Integer lives) { this.lives = lives; }

        public Integer getScore() { return score; }
        public void setScore(Integer score) { this.score = score; }

        public boolean isEliminated() { return eliminated; }
        public void setEliminated(boolean eliminated) { this.eliminated = eliminated; }

        public Integer getFinalRank() { return finalRank; }
        public void setFinalRank(Integer finalRank) { this.finalRank = finalRank; }
    }
}
