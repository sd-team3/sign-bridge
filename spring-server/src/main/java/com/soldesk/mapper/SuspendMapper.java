package com.soldesk.mapper;

import java.time.LocalDateTime;

import com.soldesk.vo.SuspendVO;

public interface SuspendMapper {

    void suspendMember(SuspendVO vo);
    LocalDateTime findLatestEndDate(int memberId);
}