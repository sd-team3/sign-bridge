package com.soldesk.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.soldesk.util.SecurityUtil;
import com.soldesk.service.CommentService;
import com.soldesk.vo.CommentVO;

@RestController
@RequestMapping("/comment")
public class CommentController {
    @Autowired
    private CommentService commentService;
    @Autowired
    private SecurityUtil securityUtil;
    
    // 댓글 목록 페이지
    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam int boardId) {
        List<CommentVO> comments = commentService.getComments(boardId);
        Integer currentMemberId = securityUtil.getCurrentMemberId();

        Map<String, Object> result = new HashMap<>();
        result.put("comments", comments);
        result.put("currentMemberId", currentMemberId);
        result.put("isLoggedIn", currentMemberId != null);
        return result;
    }

    // 댓글 작성 처리
    @PostMapping("/write")
    public Map<String, Object> writeSubmit(@ModelAttribute CommentVO comment) {
        Map<String, Object> result = new HashMap<>();
        Integer memberId = securityUtil.getCurrentMemberId();

        if(memberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }
        // 댓글 내용이 없으면 리턴
        if(comment.getCommentContent() == null || comment.getCommentContent().trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "댓글 내용을 입력해주세요.");
            return result;
        }

        comment.setMemberId(memberId);
        commentService.insertComment(comment);

        result.put("success", true);

        return result;
    }
    // 댓글 수정 처리
    @PostMapping("/update")
    public Map<String, Object> updateSubmit(@ModelAttribute CommentVO comment) {
        Map<String, Object> result = new HashMap<>();
        Integer memberId = securityUtil.getCurrentMemberId();

        if(memberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }
        CommentVO existing = commentService.getComment(comment.getCommentId());
        if(existing == null) {
            result.put("success", false);
            result.put("message", "존재하지 않는 댓글입니다.");
            return result;
        }
        if(existing.getMemberId() != memberId) {
            result.put("success", false);
            result.put("message", "본인이 작성한 댓글만 수정할 수 있습니다.");
            return result;
        }
        commentService.updateComment(comment);
        result.put("success", true);
        return result;
    }
    // 댓글 삭제 처리
    @PostMapping("/delete")
    public Map<String, Object> deleteSubmit(@RequestParam int commentId, @RequestParam int boardId) {
        Map<String, Object> result = new HashMap<>();
        Integer memberId = securityUtil.getCurrentMemberId();

        if (memberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }

        CommentVO existing = commentService.getComment(commentId);
        if (existing == null) {
            result.put("success", false);
            result.put("message", "존재하지 않는 댓글입니다.");
            return result;
        }
        // 삭제 표시된 댓글 삭제 시도 시 리턴
        if ("Y".equals(existing.getDelYn())) {
            result.put("success", false);
            result.put("message", "이미 삭제된 댓글입니다.");
            return result;
        }
        if (existing.getMemberId() != memberId) {
            result.put("success", false);
            result.put("message", "본인이 작성한 댓글만 삭제할 수 있습니다.");
            return result;
        }
        commentService.deleteComment(commentId);
        result.put("success", true);
        return result;
    }
    
}
