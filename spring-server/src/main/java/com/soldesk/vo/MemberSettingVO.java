package com.soldesk.vo;

public class MemberSettingVO {
    private Integer memberId;
    private String settingKey;
    private String settingValue;
    
    public Integer getMemberId() {
        return memberId;
    }
    public void setMemberId(Integer memberId) {
        this.memberId = memberId;
    }
    public String getSettingKey() {
        return settingKey;
    }
    public void setSettingKey(String settingKey) {
        this.settingKey = settingKey;
    }
    public String getSettingValue() {
        return settingValue;
    }
    public void setSettingValue(String settingValue) {
        this.settingValue = settingValue;
    }
}