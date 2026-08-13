package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.AdminMapper;
import com.soldesk.vo.InquiryVO;
import com.soldesk.vo.CommentVO;

@Service
public class AdminService {

    @Autowired
    private AdminMapper adminMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private CommentService commentService;

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

        // 연결된 게시글이 있으면 관리자 답변을 댓글로도 남김
        Integer boardId = adminMapper.findBoardIdByInquiry(inquiryId);
        if (boardId != null) {
            CommentVO comment = new CommentVO();
            comment.setBoardId(boardId);
            comment.setMemberId(answeredMemberId.intValue());
            comment.setCommentContent(answerContent);
            comment.setIsAdminAnswer("Y"); // 화면에서 "관리자"로 표시하기 위한 플래그
            commentService.insertComment(comment);
        }

        String linkUrl = (boardId != null) ? "/board/info?boardId=" + boardId : null;

        notificationService.notifyUser(
                sendToUserId,
                "문의 처리 알림",
                "처리 완료되었습니다",
                linkUrl,
                "INQUIRY");

        return result > 0;
    }

    public boolean createInquiry(Long memberId, String category, String title, String content, Integer boardId) {
        int result = adminMapper.insertInquiry(memberId, category, title, content, boardId);
        return result > 0;
    }

    // board 수정할 때 연결된 inquiry 내용도 같이 맞춰줌
    public void syncInquiryContentByBoard(int boardId, String category, String title, String content) {
        adminMapper.updateInquiryContentByBoardId(boardId, category, title, content);
    }

    public String getInquiryCategoryByBoardId(int boardId) {
        return adminMapper.selectInquiryCategoryByBoardId(boardId);
    }

    // 오류 신고 미처리 카운트
    public int getErrorCount() {
        return adminMapper.getErrorCount();
    }

    public int findUserIdByInquiry(Long inquiryId) {
        return adminMapper.findUserIdByInquiry(inquiryId);
    }
}