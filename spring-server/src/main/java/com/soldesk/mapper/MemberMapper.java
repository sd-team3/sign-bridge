package com.soldesk.mapper;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.MemberVO;

public interface MemberMapper {
    MemberVO findByEmail(String memberEmail);
    void insertMember(MemberVO memberVO);

    MemberVO findByProviderAndProviderId(@Param("provider") String provider, @Param("providerId") String providerId);
    void insertMemberOAuthMember(MemberVO member);
}
