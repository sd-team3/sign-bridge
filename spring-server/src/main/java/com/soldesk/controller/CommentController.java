package com.soldesk.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.soldesk.service.MemberService;
import com.soldesk.service.CommentService;
import com.soldesk.vo.CommentVO;
import com.soldesk.vo.MemberVO;

@RestController
@RequestMapping("/comment")
public class CommentController {
    @Autowired
    private CommentService commentService;
    @Autowired
    private MemberService memberService;

    private Integer getCurrentMemberId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if(auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            return null;
        }
        MemberVO member = memberService.getMemberByEmail(auth.getName());
        return member != null ? member.getMemberId() : null;
    }
    
    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam int boardId) {
        List<CommentVO> comments = commentService.getComments(boardId);
        Integer currentMemberId = getCurrentMemberId();

        Map<String, Object> result = new HashMap<>();
        result.put("comments", comments);
        result.put("currentMemberId", currentMemberId);
        result.put("isLoggedIn", currentMemberId != null);
        return result;
    }

    @PostMapping("/write")
    public Map<String, Object> writeSubmit(@ModelAttribute CommentVO comment) {
        Map<String, Object> result = new HashMap<>();
        Integer memberId = getCurrentMemberId();

        if(memberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }
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
    @PostMapping("/update")
    public Map<String, Object> updateSubmit(@ModelAttribute CommentVO comment) {
        Map<String, Object> result = new HashMap<>();
        Integer memberId = getCurrentMemberId();

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
    @PostMapping("/delete")
    public Map<String, Object> deleteSubmit(@RequestParam int commentId, @RequestParam int boardId) {
        Map<String, Object> result = new HashMap<>();
        Integer memberId = getCurrentMemberId();

        if (memberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }

        CommentVO existing = commentService.getComment(commentId);
        if (existing == null) {
            result.put("success", false);
            result.put("message", "이미 삭제된 댓글입니다.");
            return result;
        }
        if (existing.getMemberId() != memberId) {
            result.put("success", false);
            result.put("message", "본인이 작성한 댓글만 삭제할 수 있습니다.");
            return result;
        }

        try {
            commentService.deleteComment(commentId);
            result.put("success", true);
        } catch (DataIntegrityViolationException e) {
            result.put("success", false);
            result.put("message", "답글이 달린 댓글은 삭제할 수 없습니다.");
        }
        return result;
    }
    
}
