package com.soldesk.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.soldesk.mapper.MemberSettingMapper;
import com.soldesk.vo.MemberSettingVO;

@Service
public class MemberSettingService {

    @Autowired
    private MemberSettingMapper memberSettingMapper;

    @Transactional(readOnly = true)
    public String getValue(int memberId, String key) {
        return memberSettingMapper.findValue(memberId, key);
    }
    @Transactional
    public void setValue(int memberId, String key, String value) {
        memberSettingMapper.upsertValue(memberId, key, value);
    }
    @Transactional
    public void removeValue(int memberId, String key) {
        memberSettingMapper.deleteValue(memberId, key);
    }
    @Transactional(readOnly = true)
    public List<MemberSettingVO> getByPrefix(int memberId, String prefix) {
        return memberSettingMapper.findByKeyPrefix(memberId, prefix);
    }



    // ======= 알림 영역 ========
    private static final String PREFIX = "ALARM_";

    // row 없으면 기본 켜짐
    public boolean isEnabled(int memberId, String notificationType) {
        String value = getValue(memberId, PREFIX + notificationType);
        return value == null || "Y".equals(value);
    }
    public void setAlarm(int memberId, String notificationType, boolean on) {
        String key = PREFIX + notificationType;
        if (on) {
            removeValue(memberId, key); // 기본값(켜짐)으로 되돌림
        } else {
            setValue(memberId, key, "N");
        }
    }
    // 꺼진 타입 목록
    public List<String> getOffTypes(int memberId) {
        return getByPrefix(memberId, PREFIX).stream()
                .filter(s -> "N".equals(s.getSettingValue()))
                .map(s -> s.getSettingKey().substring(PREFIX.length()))
                .collect(Collectors.toList());
    }
}