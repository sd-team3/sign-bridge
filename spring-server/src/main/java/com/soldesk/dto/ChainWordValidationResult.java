package com.soldesk.dto;

/** 단어 검증 결과. ChainWordValidationService 의 반환값. */
public class ChainWordValidationResult {
    private final boolean valid;
    private final String reasonCode; // invalid 인 경우만 (ChainWordLogVO.REASON_*)
    private final Long chainWordId;  // valid 인 경우, chain_word 테이블의 id (기존/신규 모두)

    private ChainWordValidationResult(boolean valid, String reasonCode, Long chainWordId) {
        this.valid = valid;
        this.reasonCode = reasonCode;
        this.chainWordId = chainWordId;
    }

    public static ChainWordValidationResult valid(Long chainWordId) {
        return new ChainWordValidationResult(true, null, chainWordId);
    }

    public static ChainWordValidationResult invalid(String reasonCode) {
        return new ChainWordValidationResult(false, reasonCode, null);
    }

    public boolean isValid() { return valid; }
    public String getReasonCode() { return reasonCode; }
    public Long getChainWordId() { return chainWordId; }
}
