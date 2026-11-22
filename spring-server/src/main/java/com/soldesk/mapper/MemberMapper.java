package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.DailySignupVO;
import com.soldesk.vo.MemberVO;

public interface MemberMapper {
    MemberVO findByEmail(String memberEmail);
    void insertMember(MemberVO memberVO);

    MemberVO findByProviderAndProviderId(@Param("provider") String provider, @Param("providerId") String providerId);
    void insertMemberOAuthMember(MemberVO member);
    

    int countAll();


    int countTodayMember();


    List<DailySignupVO> getWeeklySignupList();


    List<MemberVO> getAllMembers(
            @Param("start") int start,
            @Param("count") int count,
            @Param("role") String role,
            @Param("status") String status,
            @Param("keyword") String keyword,
            @Param("sort") String sort
    );

    int getMemberCount(@Param("role") String role, @Param("status") String status, @Param("keyword") String keyword);


    MemberVO findById(int memberId);

    MemberVO getMemberByEmail(String email);

    void updateStatus(@Param("memberId") int memberId, @Param("status") String status);

    void suspendStatus(int memberId);

    void deleteMember(int memberId);

    void updateMemberName(@Param("memberId") int memberId, @Param("memberName") String memberName);

    void updatePassword(@Param("memberId") int memberId, @Param("encodedPassword") String encodedPassword);


    void addPoint(@Param("memberId") int memberId, @Param("delta") int delta);

}
