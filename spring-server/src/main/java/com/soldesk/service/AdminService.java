package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.AdminMapper;
import com.soldesk.vo.InquiryVO;

@Service
public class AdminService {

    @Autowired
    private AdminMapper adminMapper;

    public List<InquiryVO> getInquiryList(String category, String status) {
        if ("ALL".equalsIgnoreCase(status)) {
            return adminMapper.selectByCategory(category);
        }
        return adminMapper.selectByCategoryAndStatus(category, status);
    }

    public int getStatusCount(String category, String status) {
        return adminMapper.countByCategoryAndStatus(category, status);
    }

    public boolean answerInquiry(Long inquiryId, String answerContent, Long answeredMemberId) {
        int result = adminMapper.updateAnswer(inquiryId, answerContent, answeredMemberId);
        return result > 0;
    }

    public boolean createInquiry(Long memberId, String category, String title, String content) {
        int result = adminMapper.insertInquiry(memberId, category, title, content);
        return result > 0;
    }

    // 오류 신고 미처리 카운트
    public int getErrorCount() {
        return adminMapper.getErrorCount();
    }
}