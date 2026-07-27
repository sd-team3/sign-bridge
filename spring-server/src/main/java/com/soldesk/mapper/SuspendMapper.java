package com.soldesk.mapper;

public interface SuspendMapper {

    void suspendMember(int memberId, String suspendDays, String reason);
}