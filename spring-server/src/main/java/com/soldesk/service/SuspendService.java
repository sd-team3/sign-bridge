package com.soldesk.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.SuspendMapper;

@Service
public class SuspendService {
    
    @Autowired
    private SuspendMapper suspendMapper;

    @Transactional
    public void suspendMember(int memberId, String suspendDays, String reason) {
        suspendMapper.suspendMember(memberId, suspendDays, reason);
    }

}
