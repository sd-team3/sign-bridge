package com.soldesk.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.soldesk.service.SseService;

@RestController
@RequestMapping("/sse")
public class SseController {

    @Autowired
    private SseService sseService;
    
    @GetMapping(value = "/subscribe/{userId}", produces = "text/event-stream")
    public SseEmitter subscribe(@PathVariable int userId) {
        return sseService.subscribe(userId);
    }
    @GetMapping("/test/{userId}")
    @ResponseBody
    public String test(@PathVariable int userId) {
        sseService.sendToClient(userId, "notification", "테스트 알림입니다");
        return "sent";
    }

}
