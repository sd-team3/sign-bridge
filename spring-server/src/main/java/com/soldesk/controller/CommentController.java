package com.soldesk.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.soldesk.service.MemberService;
import com.soldesk.service.CommentService;
import com.soldesk.vo.CommentVO;

@Controller
@RequestMapping("/comment")
public class CommentController {
    @Autowired
    private CommentService commentService;
    @Autowired
    private MemberService memberService;

    @PostMapping("/write")
    public String writeSubmit(@ModelAttribute CommentVO comment) {
        String memberEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        int memberId = memberService.getMemberByEmail(memberEmail).getMemberId();
        comment.setMemberId(memberId);
        commentService.insertComment(comment);



        return "redirect:/board/info?boardId=" + comment.getBoardId();
    }
    @PostMapping("/update")
    public String updateSubmit(@ModelAttribute CommentVO comment) {
        commentService.updateComment(comment);
        return "redirect:/board/info?boardId=" + comment.getBoardId();
    }
    @PostMapping("/delete")
    public String deleteSubmit(@RequestParam int commentId, @RequestParam int boardId) {
        commentService.deleteComment(commentId);
        return "redirect:/board/info?boardId=" + boardId;
    }
    
}
