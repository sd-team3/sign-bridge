package com.soldesk.security;

import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

public class CustomUserDetail extends User {
    
    private final int memberId;
    private final String memberName;

    public CustomUserDetail(int memberId, String memberName, String memberEmail, String memberPassword, 
                            boolean enabled,
                            Collection<? extends GrantedAuthority> authorities) {

        super(memberEmail, memberPassword, enabled, true, true, true, authorities);
        this.memberId = memberId;
        this.memberName = memberName;
    }

    public int getMemberId() {
        return memberId;
    }
    
    public String getMemberName(){
        return memberName;
    }
}
