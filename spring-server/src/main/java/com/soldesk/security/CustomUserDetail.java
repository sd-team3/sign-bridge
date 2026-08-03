package com.soldesk.security;

import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

public class CustomUserDetail extends User {
    
    private final int memberId;

    public CustomUserDetail(int memberId, String memberEmail, String memberPassword, 
                            boolean enabled,
                            Collection<? extends GrantedAuthority> authorities) {

        super(memberEmail, memberPassword, enabled, true, true, true, authorities);
        this.memberId = memberId;
    }

    public int getMemberId() {
        return memberId;
    }
    
}
