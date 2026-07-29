package com.soldesk.controller;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.soldesk.service.OAuthService;

@Controller
@RequestMapping("/oauth2")
public class OAuthController {

    @Autowired
    private OAuthService oAuthService;
    
    @GetMapping("/google")
    public void googleLogin(HttpServletResponse response) throws IOException {
        response.sendRedirect(oAuthService.getGoogleAuthUrl());
    }
    @GetMapping("/google/callback")
    public String googleCallback(@RequestParam String code, 
        HttpServletRequest request, HttpServletResponse response) throws IOException, InterruptedException {
        oAuthService.processGoogle(code, request, response);
        return "redirect:/";        
    }

    @GetMapping("/naver")
    public void naverLogin(HttpServletResponse response, HttpSession session) throws IOException {
        response.sendRedirect(oAuthService.getNaverAuthUrl(session));
    }
    @GetMapping("/naver/callback")
    public String naverCallback(@RequestParam String code, @RequestParam String state,
        HttpServletRequest request, HttpServletResponse response) throws IOException, InterruptedException {
        oAuthService.processNaver(code, state, request, response);
        return "redirect:/";        
    }

    @GetMapping("/kakao")
    public void kakaoLogin(HttpServletResponse response) throws IOException {
        response.sendRedirect(oAuthService.getKakaoAuthUrl());
    }
    @GetMapping("/kakao/callback")
    public String kakaoCallback(@RequestParam String code,
        HttpServletRequest request, HttpServletResponse response) throws IOException, InterruptedException {
        oAuthService.processKakao(code, request, response);
        return "redirect:/";        
    }
}
