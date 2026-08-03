package com.soldesk.controller;

import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.soldesk.service.MemberService;
import com.soldesk.util.SecurityUtil;
import com.soldesk.vo.MemberVO;

@Controller
@RequestMapping("/member")
public class MemberController {
    @Autowired
    private MemberService memberService;
    @Autowired
    private SecurityUtil securityUtil;
    @Autowired
    private PasswordEncoder passwordEncoder;

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
    
    @GetMapping("/mypage")
    public String mypage(Model model) {
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if(currentMemberId == null) {
            return "redirect:/member/login";
        }
        MemberVO member = memberService.getMemberById(currentMemberId);
        model.addAttribute("member", member);
        return "member/mypage";
    }
    @PostMapping("/update")
    @ResponseBody
    public Map<String, Object> updateMember(@RequestParam int memberId, @RequestParam String memberName) {
        Map<String, Object> result = new HashMap<>();

        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if (currentMemberId == null || !currentMemberId.equals(memberId)) {
            result.put("success", false);
            result.put("message", "권한이 없습니다.");
            return result;
        }

        memberService.updateMemberName(memberId, memberName);
        result.put("success", true);
        return result;
    }

    @PostMapping("/passUpdate")
    @ResponseBody
    public Map<String, Object> updatePassword(@RequestParam String currentPassword, @RequestParam String newPassword) {
        Map<String, Object> result = new HashMap<>();
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if(currentMemberId == null) {
            result.put("success", false);
            result.put("message", false);
            return result;
        }

        MemberVO member = memberService.getMemberById(currentMemberId);
        if (!"LOCAL".equals(member.getProvider())) {
            result.put("success", false);
            result.put("message", "소셜 로그인 계정은 비밀번호를 변경할 수 없습니다.");
            return result;
        }

        if (!passwordEncoder.matches(currentPassword, member.getMemberPassword())) {
            result.put("success", false);
            result.put("message", "현재 비밀번호가 일치하지 않습니다.");
            return result;
        }

        String encodedNewPassword = passwordEncoder.encode(newPassword);
        memberService.updatePassword(currentMemberId, encodedNewPassword);
        result.put("success", true);
        return result;
    }

    @PostMapping("/delete")
    @ResponseBody
    public Map<String, Object> deleteMember(@RequestParam(required = false) String password,
        HttpServletRequest request) {
        
        Map<String, Object> result = new HashMap<>();
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if(currentMemberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }
        
        MemberVO member = memberService.getMemberById(currentMemberId);
        
        if("LOCAL".equals(member.getProvider())) {
            if(password == null || !passwordEncoder.matches(password, member.getMemberPassword())) {
                result.put("success", false);
                result.put("message", "비밀번호가 일치하지 않습니다.");
                return result;
            }
        }
        memberService.deleteMember(currentMemberId);

        request.getSession().invalidate();
        SecurityContextHolder.clearContext();
        
        result.put("success", true);
        return result;
    }


}
