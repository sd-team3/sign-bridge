package com.soldesk.dto;


public class ChainWordValidationResult {
    private final boolean valid;
    private final String reasonCode;
    private final Long chainWordId;

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
