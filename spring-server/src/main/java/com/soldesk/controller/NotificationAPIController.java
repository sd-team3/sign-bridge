package com.soldesk.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.soldesk.security.CustomUserDetail;

@RestController
@RequestMapping("/notification")
public class NotificationAPIController {
    
    // 헤더에서 api로 받아오는 멤버 아이디
    @GetMapping("/me")
    public Map<String, Object> getMyInfo(@AuthenticationPrincipal CustomUserDetail userDetails) {
        Map<String, Object> result = new HashMap<>();
        if (userDetails == null) {
            result.put("memberId", null);
            return result;
        }
        result.put("memberId", userDetails.getMemberId());
        return result;
    }

}
