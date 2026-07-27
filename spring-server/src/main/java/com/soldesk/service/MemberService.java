package com.soldesk.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.MemberMapper;
import com.soldesk.vo.DailySignupVO;
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
    // 전체 멤버 수
    @Transactional
    public int getMemberCount() {
        return memberMapper.countAll();
    }
    // 오늘 등록한 회원 수
    @Transactional
    public int newUserToday() {
        return memberMapper.countTodayMember();
    }
    // 주간 일별 추가 회원
    @Transactional
    public List<Integer> getWeeklySignupCounts() {
        List<DailySignupVO> raw = memberMapper.getWeeklySignupList();
        
        Map<LocalDate, Integer> countMap = new LinkedHashMap<>();
        LocalDate monday = LocalDate.now().with(DayOfWeek.MONDAY);
        for (int i = 0; i < 7; i++) {
            countMap.put(monday.plusDays(i), 0);
        }

        for (DailySignupVO vo : raw) {
            LocalDate day = LocalDate.parse(vo.getDay());
            if (countMap.containsKey(day)) {
                countMap.put(day, vo.getCount());
            }
        }
        return new ArrayList<>(countMap.values());
    }
    // 어드민 유저 수 필터 거치기
    @Transactional
    public int adminGetMemberCount(String role, String status, String keyword) {
        return memberMapper.getMemberCount(role, status, keyword);
    }

    // 어드민 멤버 리스트 뽑아오기
    @Transactional
    public List<MemberVO> getMemberList(int page, int pageSize, String role, String status, String keyword, String sort) {
        int start = (page - 1) * pageSize;
        return memberMapper.getAllMembers(start, pageSize, role, status, keyword, sort);
    }

    // 특정 회원 정보 가져오기
    @Transactional
    public MemberVO getMemberInfo(int memberId) {
        return memberMapper.getMemberInfo(memberId);
    }

}
