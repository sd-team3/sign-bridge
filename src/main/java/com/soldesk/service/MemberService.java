package com.soldesk.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.MemberMapper;
import com.soldesk.vo.MemberVO;

@Service
public class MemberService {

    @Autowired
    private MemberMapper memberMapper;
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Transactional
    public boolean isEmailAvailable(String email) {
        MemberVO memberVO = memberMapper.findByEmail(email);
        if(memberVO == null) return true;
        return false;
    }
    @Transactional
    public void join(MemberVO member) {
        String dbPassword = passwordEncoder.encode(member.getMemberPassword());
        member.setMemberPassword(dbPassword);
        memberMapper.insertMember(member);
    }
}
