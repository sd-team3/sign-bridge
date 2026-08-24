package com.soldesk.vo;

import java.time.LocalDateTime;

/** chain_room_member 테이블 매핑. 끝말잇기 게임방 참여자. */
public class ChainRoomMemberVO {

    private Long chainRoomId;
    private Integer memberId;
    private Integer turnNo;
    private LocalDateTime joinedDate;
    private LocalDateTime leftDate;
    private Integer lives;
    private String eliminatedYn; // Y/N
    private Integer score;
    private Integer finalRank;
    private LocalDateTime eliminatedDate;

    // join 해서 같이 조회할 때 채워지는 표시용 필드 (member 테이블)
    private String memberName;
    private String memberProfileImage;

    public Long getChainRoomId() { return chainRoomId; }
    public void setChainRoomId(Long chainRoomId) { this.chainRoomId = chainRoomId; }

    public Integer getMemberId() { return memberId; }
    public void setMemberId(Integer memberId) { this.memberId = memberId; }

    public Integer getTurnNo() { return turnNo; }
    public void setTurnNo(Integer turnNo) { this.turnNo = turnNo; }

    public LocalDateTime getJoinedDate() { return joinedDate; }
    public void setJoinedDate(LocalDateTime joinedDate) { this.joinedDate = joinedDate; }

    public LocalDateTime getLeftDate() { return leftDate; }
    public void setLeftDate(LocalDateTime leftDate) { this.leftDate = leftDate; }

    public Integer getLives() { return lives; }
    public void setLives(Integer lives) { this.lives = lives; }

    public String getEliminatedYn() { return eliminatedYn; }
    public void setEliminatedYn(String eliminatedYn) { this.eliminatedYn = eliminatedYn; }

    public boolean isEliminated() { return "Y".equals(eliminatedYn); }

    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }

    public Integer getFinalRank() { return finalRank; }
    public void setFinalRank(Integer finalRank) { this.finalRank = finalRank; }

    public LocalDateTime getEliminatedDate() { return eliminatedDate; }
    public void setEliminatedDate(LocalDateTime eliminatedDate) { this.eliminatedDate = eliminatedDate; }

    public String getMemberName() { return memberName; }
    public void setMemberName(String memberName) { this.memberName = memberName; }

    public String getMemberProfileImage() { return memberProfileImage; }
    public void setMemberProfileImage(String memberProfileImage) { this.memberProfileImage = memberProfileImage; }
}
