package com.soldesk.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.soldesk.service.LearnService;

@Controller
@RequestMapping("/learn")
public class LearnController {

    @Autowired
    private LearnService learnService;

    @GetMapping("")
    public String main(){
        return "learn/main";
    }

    @GetMapping("/jamo")
    public String jamo(Model model){
        model.addAttribute("consonants", learnService.getConsonants());
        model.addAttribute("vowels", learnService.getVowels());
        return "learn/jamo";
    }
}
