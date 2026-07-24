package com.soldesk.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.soldesk.service.MemberService;
import com.soldesk.vo.EmailCheckResponse;

@RestController
@RequestMapping("/member")
public class MemberAPIController {
    @Autowired
    private MemberService memberService;

    @GetMapping("/check-email")
    public EmailCheckResponse checkEmail(@RequestParam String memberEmail) {
        boolean available = memberService.isEmailAvailable(memberEmail);
        String message = available ? "사용가능한 이메일입니다" : "이미 가입된 이메일입니다";
        
        EmailCheckResponse emailCheckResponse = new EmailCheckResponse();
        emailCheckResponse.setAvailable(available);
        emailCheckResponse.setMessage(message);
        return emailCheckResponse;
    }
}
