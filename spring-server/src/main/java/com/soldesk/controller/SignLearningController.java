package com.soldesk.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class SignLearningController {
    @GetMapping("/learn/signs")
    public String learn() {
        return "learn/signs";
    }
}
