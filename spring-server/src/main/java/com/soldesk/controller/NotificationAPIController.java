package com.soldesk.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.soldesk.security.CustomUserDetail;
import com.soldesk.service.NotificationService;
import com.soldesk.vo.NotificationVO;
import org.springframework.web.bind.annotation.PostMapping;


@RestController
@RequestMapping("/notification")
public class NotificationAPIController {

    @Autowired
    private NotificationService notificationService;
    
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

    @GetMapping("/list")
    public List<NotificationVO> getList (@AuthenticationPrincipal CustomUserDetail userDetail) {

        int memberId = userDetail.getMemberId();
        List<NotificationVO> result = notificationService.getNotificationList(memberId);
        return result;
    } 

    @PostMapping("/read/{notificationId}")
    public ResponseEntity<Void> read(@PathVariable int notificationId) {
        notificationService.readNotification(notificationId);
        return ResponseEntity.ok().build();
    }
        

}
