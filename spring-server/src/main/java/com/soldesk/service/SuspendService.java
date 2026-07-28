package com.soldesk.service;

import java.time.LocalDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.SuspendMapper;
import com.soldesk.vo.SuspendVO;

@Service
public class SuspendService {
    
    @Autowired
    private SuspendMapper suspendMapper;

    @Transactional
    public void suspendMember(int memberId, String suspendDays, String reason, int adminId) {
        SuspendVO vo = new SuspendVO();
        vo.setMemberId(memberId);
        vo.setAdminId(adminId);
        vo.setReason(reason);
        vo.setStartDate(LocalDateTime.now());

        if ("permanent".equals(suspendDays)) {
            vo.setEndDate(null);
        } else {
            int days = Integer.parseInt(suspendDays);
            vo.setEndDate(LocalDateTime.now().plusDays(days));
        }

        suspendMapper.suspendMember(vo);
    }

}
