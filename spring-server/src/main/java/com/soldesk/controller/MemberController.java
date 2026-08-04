package com.soldesk.controller;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.soldesk.service.MemberService;
import com.soldesk.vo.MemberVO;

@Controller
@RequestMapping("/member")
public class MemberController {
    @Autowired
    private MemberService memberService;

    @GetMapping("/join")
    public String join(@ModelAttribute("joinMember") MemberVO member) {
        return "member/join";
    }
    @PostMapping("/join")
    public String joinSubmit(@Valid @ModelAttribute("joinMember") 
        MemberVO member, BindingResult bindingResult) {
            if(bindingResult.hasErrors()) {
                bindingResult.getAllErrors().forEach(error -> 
                    System.out.println(error.toString())
                );
                return "member/join";
            }
            memberService.join(member);
            return "redirect:/member/login";
    }

    @GetMapping("/login")
    public String login() {
        return "member/login";
    }


}
