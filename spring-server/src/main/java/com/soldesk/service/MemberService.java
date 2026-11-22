package com.soldesk.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.MemberMapper;
import com.soldesk.mapper.SuspendMapper;
import com.soldesk.vo.DailySignupVO;
import com.soldesk.vo.MemberVO;

@Service
public class MemberService {

    @Autowired
    private MemberMapper memberMapper;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private CommentService commentService;
    @Autowired
    private BoardService boardService;
    @Autowired SuspendMapper suspendMapper;
    
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

    @Transactional
    public int getMemberCount() {
        return memberMapper.countAll();
    }

    @Transactional
    public int newUserToday() {
        return memberMapper.countTodayMember();
    }

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

    @Transactional
    public int adminGetMemberCount(String role, String status, String keyword) {
        return memberMapper.getMemberCount(role, status, keyword);
    }


    @Transactional
    public List<MemberVO> getMemberList(int page, int pageSize, String role, String status, String keyword, String sort) {
        int start = (page - 1) * pageSize;
        return memberMapper.getAllMembers(start, pageSize, role, status, keyword, sort);
    }


    @Transactional
    public MemberVO getMemberInfo(int memberId) {
        MemberVO member = memberMapper.findById(memberId);
        checkAndReleaseIfExpired(member);
        return member;
    }

    @Transactional
    public MemberVO getMemberById(int memberId) {
        MemberVO member = memberMapper.findById(memberId);
        return member;
    }


    @Transactional
    public MemberVO getMemberByEmail(String adminEmail) {
        return memberMapper.getMemberByEmail(adminEmail);
    }


    @Transactional
    public void suspendMember(int memberId) {
        memberMapper.suspendStatus(memberId);
    }


    @Transactional
    public void checkAndReleaseIfExpired(MemberVO member) {
        if (!"SUSPEND".equals(member.getStatus())) return;

        LocalDateTime latestEndDate = suspendMapper.findLatestEndDate(member.getMemberId());
        if (latestEndDate != null && latestEndDate.isBefore(LocalDateTime.now())) {
            memberMapper.updateStatus(member.getMemberId(), "ACTIVE");
            member.setStatus("ACTIVE");
        }
    }


    @Transactional
    public void deleteMember(int memberId) {
        boardService.anonymizeMemberBoards(memberId);
        commentService.anonymizeMemberComments(memberId);
        memberMapper.deleteMember(memberId);
    }


    @Transactional
    public void updateMemberName(int memberId, String memberName) {
        memberMapper.updateMemberName(memberId, memberName);
    }


    @Transactional
    public void updatePassword(int memberId, String encodedPassword) {
        memberMapper.updatePassword(memberId, encodedPassword);
    }

}
