package com.soldesk.util;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import com.soldesk.service.MemberService;
import com.soldesk.vo.MemberVO;

@Component
public class SecurityUtil {

    @Autowired
    private MemberService memberService;

    // 현재 로그인한 사용자의 MemberId, 비로그인이면 null 반환
    public Integer getCurrentMemberId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            return null;
        }
        MemberVO member = memberService.getMemberByEmail(auth.getName());
        return member != null ? member.getMemberId() : null;
    }

    // 현재 로그인한 사용자가 어드민인지 확인
    public boolean isAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return false;
        return auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}