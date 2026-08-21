package com.soldesk.vo;

import java.time.LocalDateTime;

/** chain_word_log 테이블 매핑. 끝말잇기 단어 시도 기록 (게임 종료 후 "전적"의 진행 로그로 그대로 사용됨). */
public class ChainWordLogVO {

    // invalid_reason_code 값
    public static final String REASON_WRONG_START_CHAR = "WRONG_START_CHAR";
    public static final String REASON_DUPLICATE = "DUPLICATE";
    public static final String REASON_NOT_FOUND = "NOT_FOUND";
    public static final String REASON_INVALID_FORM = "INVALID_FORM"; // ~하다/~되다 등 범용 어미
    public static final String REASON_TIMEOUT = "TIMEOUT";

    private Long chainWordLogId;
    private Long chainRoomId;
    private Integer memberId;
    private Long chainWordId;
    private String attemptedWord;
    private Integer turnNo;
    private String isValid; // Y/N
    private String invalidReasonCode;
    private LocalDateTime regDate;

    // 화면 표시용
    private String memberName;

    public Long getChainWordLogId() { return chainWordLogId; }
    public void setChainWordLogId(Long chainWordLogId) { this.chainWordLogId = chainWordLogId; }

    public Long getChainRoomId() { return chainRoomId; }
    public void setChainRoomId(Long chainRoomId) { this.chainRoomId = chainRoomId; }

    public Integer getMemberId() { return memberId; }
    public void setMemberId(Integer memberId) { this.memberId = memberId; }

    public Long getChainWordId() { return chainWordId; }
    public void setChainWordId(Long chainWordId) { this.chainWordId = chainWordId; }

    public String getAttemptedWord() { return attemptedWord; }
    public void setAttemptedWord(String attemptedWord) { this.attemptedWord = attemptedWord; }

    public Integer getTurnNo() { return turnNo; }
    public void setTurnNo(Integer turnNo) { this.turnNo = turnNo; }

    public String getIsValid() { return isValid; }
    public void setIsValid(String isValid) { this.isValid = isValid; }

    public String getInvalidReasonCode() { return invalidReasonCode; }
    public void setInvalidReasonCode(String invalidReasonCode) { this.invalidReasonCode = invalidReasonCode; }

    public LocalDateTime getRegDate() { return regDate; }
    public void setRegDate(LocalDateTime regDate) { this.regDate = regDate; }

    public String getMemberName() { return memberName; }
    public void setMemberName(String memberName) { this.memberName = memberName; }
}
