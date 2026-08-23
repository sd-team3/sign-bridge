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
    
    // 구글 OAuth 페이지
    @GetMapping("/google")
    public void googleLogin(HttpServletResponse response) throws IOException {
        response.sendRedirect(oAuthService.getGoogleAuthUrl());
    }
    // 구글 콜백 메서드
    @GetMapping("/google/callback")
    public String googleCallback(@RequestParam String code, 
        HttpServletRequest request, HttpServletResponse response) throws IOException, InterruptedException {
        oAuthService.processGoogle(code, request, response);
        return "redirect:/";        
    }
    // 네이버 OAuth 페이지
    @GetMapping("/naver")
    public void naverLogin(HttpServletResponse response, HttpSession session) throws IOException {
        response.sendRedirect(oAuthService.getNaverAuthUrl(session));
    }
    // 네이버 콜백 메서드
    @GetMapping("/naver/callback")
    public String naverCallback(@RequestParam String code, @RequestParam String state,
        HttpServletRequest request, HttpServletResponse response) throws IOException, InterruptedException {
        oAuthService.processNaver(code, state, request, response);
        return "redirect:/";        
    }
    // 카카오 OAuth 페이지
    @GetMapping("/kakao")
    public void kakaoLogin(HttpServletResponse response) throws IOException {
        response.sendRedirect(oAuthService.getKakaoAuthUrl());
    }
    // 카카오 콜백 메서드
    @GetMapping("/kakao/callback")
    public String kakaoCallback(@RequestParam String code,
        HttpServletRequest request, HttpServletResponse response) throws IOException, InterruptedException {
        oAuthService.processKakao(code, request, response);
        return "redirect:/";        
    }
}
