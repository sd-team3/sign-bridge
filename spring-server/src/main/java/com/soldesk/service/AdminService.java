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

    @Autowired
    private NotificationService notificationService;

    public List<InquiryVO> getInquiryList(String category, String status) {
        if ("ALL".equalsIgnoreCase(status)) {
            return adminMapper.selectByCategory(category);
        }
        return adminMapper.selectByCategoryAndStatus(category, status);
    }

    public int getStatusCount(String category, String status) {
        return adminMapper.countByCategoryAndStatus(category, status);
    }

    public boolean answerInquiry(Long inquiryId, String answerContent, Long answeredMemberId, int sendToUserId) {
        int result = adminMapper.updateAnswer(inquiryId, answerContent, answeredMemberId);
        notificationService.notifyUser(
            sendToUserId,
            "문의 처리 알림",
            "처리 완료되었습니다. 글을 확인해주세요");

        return result > 0;
    }

    // 오류 신고 미처리 카운트
    public int getErrorCount() {
        return adminMapper.getErrorCount();
    }

    public int findUserIdByInquiry(Long inquiryId) {
        return adminMapper.findUserIdByInquiry(inquiryId);
    }
}