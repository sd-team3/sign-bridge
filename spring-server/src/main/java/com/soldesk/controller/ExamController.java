package com.soldesk.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.soldesk.service.ExamService;

@Controller
@RequestMapping("/exam")
public class ExamController {

    @Autowired
    private ExamService examService;

    @GetMapping("/setup")
    public String setup() {
        return "exam/setup";
    }

    @GetMapping("/choice")
    public String choice() {
        return "exam/choice";
    }

    @GetMapping("/motion")
    public String motion() {
        return "exam/motion";
    }

    @GetMapping("/result")
    public String result() {
        return "exam/result";
    }
}
