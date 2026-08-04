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
    
    // 전체 멤버 수
    int countAll();

    // 오늘 추가된 회원 수
    int countTodayMember();

    // 주간 일별 추가 유저 수
    List<DailySignupVO> getWeeklySignupList();

    // 어드민 페이지 멤버 리스트
    List<MemberVO> getAllMembers(
            @Param("start") int start,
            @Param("count") int count,
            @Param("role") String role,
            @Param("status") String status,
            @Param("keyword") String keyword,
            @Param("sort") String sort
    );
    // 어드민 필터 거쳐서 멤버 수 세기
    int getMemberCount(@Param("role") String role, @Param("status") String status, @Param("keyword") String keyword);

    // 특정 회원 정보 가져오기
    MemberVO findById(int memberId);

    MemberVO getMemberByEmail(String email);

    void updateStatus(@Param("memberId") int memberId, @Param("status") String status);

    void suspendStatus(int memberId);

    void deleteMember(int memberId);
}
