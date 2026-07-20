package com.soldesk.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.MemberMapper;
import com.soldesk.vo.MemberVO;

@Service
public class MemberUserDetailsService implements UserDetailsService {
    @Autowired
    private MemberMapper memberMapper;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        MemberVO member = memberMapper.findByEmail(username); // DB에서 사용자 조회
        if(member == null) throw new UsernameNotFoundException(username + "의 회원정보를 찾을 수 없습니다.");
        // email과 일치하는 회원 정보 없음

        return User.builder()
                        .username(member.getMemberEmail())
                        .password(member.getMemberPassword())
                        .roles(resolveRole(member.getRole()))
                        .build();
    }
    // 권한 설정(단순 문자열을 관리자 또는 유저 권한 부여)
    private String resolveRole(String role) {
        if("ADMIN".equalsIgnoreCase(role)) return "ADMIN";
        return "USER";
    }
}
