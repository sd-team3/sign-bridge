package com.soldesk.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.MemberSettingVO;

public interface MemberSettingMapper {
    String findValue(@Param("memberId") Integer memberId, @Param("settingKey") String settingKey);
    void upsertValue(@Param("memberId") Integer memberId,
                      @Param("settingKey") String settingKey,
                      @Param("settingValue") String settingValue);

    void deleteValue(@Param("memberId") Integer memberId, @Param("settingKey") String settingKey);
    List<MemberSettingVO> findByKeyPrefix(@Param("memberId") Integer memberId, @Param("prefix") String prefix);
}