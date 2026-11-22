package com.soldesk.security;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.MemberMapper;
import com.soldesk.mapper.SuspendMapper;
import com.soldesk.vo.MemberVO;

@Service
public class MemberUserDetailsService implements UserDetailsService {
    @Autowired
    private MemberMapper memberMapper;

    @Autowired
    private SuspendMapper suspendMapper;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        MemberVO member = memberMapper.findByEmail(username);
        if(member == null) throw new UsernameNotFoundException(username + "의 회원정보를 찾을 수 없습니다.");


        System.out.println("### status = [" + member.getStatus() + "]");

        checkAndReleaseIfExpired(member);

        boolean enabled = !"SUSPEND".equals(member.getStatus()); 

        return new CustomUserDetail(member.getMemberId(),
                                    member.getMemberName(),
                                    member.getMemberEmail(), 
                                    member.getMemberPassword(), 
                                    enabled, 
                                    List.of(new SimpleGrantedAuthority("ROLE_" + resolveRole(member.getRole()))));
    }



    private void checkAndReleaseIfExpired(MemberVO member) {
        if (!"SUSPENDED".equals(member.getStatus())) return;

        LocalDateTime latestEndDate = suspendMapper.findLatestEndDate(member.getMemberId());
        if (latestEndDate != null && latestEndDate.isBefore(LocalDateTime.now())) {
            memberMapper.updateStatus(member.getMemberId(), "ACTIVE");
            member.setStatus("ACTIVE");
        }
    }

    private String resolveRole(String role) {
        if("ADMIN".equalsIgnoreCase(role)) return "ADMIN";
        return "USER";
    }
}
