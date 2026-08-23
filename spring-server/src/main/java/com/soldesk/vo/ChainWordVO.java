package com.soldesk.vo;

import java.time.LocalDateTime;

/** chain_word 테이블 매핑. 끝말잇기 검증 완료된 단어집 (sign_word 와 별개). */
public class ChainWordVO {

    private Long chainWordId;
    private String wordName;
    private String firstChar;
    private String lastChar;
    private LocalDateTime regDate;

    public Long getChainWordId() { return chainWordId; }
    public void setChainWordId(Long chainWordId) { this.chainWordId = chainWordId; }

    public String getWordName() { return wordName; }
    public void setWordName(String wordName) { this.wordName = wordName; }

    public String getFirstChar() { return firstChar; }
    public void setFirstChar(String firstChar) { this.firstChar = firstChar; }

    public String getLastChar() { return lastChar; }
    public void setLastChar(String lastChar) { this.lastChar = lastChar; }

    public LocalDateTime getRegDate() { return regDate; }
    public void setRegDate(LocalDateTime regDate) { this.regDate = regDate; }
}
