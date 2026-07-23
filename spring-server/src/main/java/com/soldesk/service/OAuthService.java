package com.soldesk.service;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.soldesk.mapper.MemberMapper;
import com.soldesk.security.MemberUserDetailsService;
import com.soldesk.vo.MemberVO;

@Service
public class OAuthService {
    @Value("${google.client-id}")
    private String googleClientId;
    @Value("${google.client-secret}")
    private String googleClientSecret;
    @Value("${google.redirect-uri}")
    private String googleRedirectUri;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private MemberMapper memberMapper;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private MemberUserDetailsService memberUserDetailsService;

    public String getGoogleAuthUrl() {
        return "https://accounts.google.com/o/oauth2/v2/auth"
         + "?client_id=" + googleClientId
         + "&redirect_uri=" + URLEncoder.encode(googleRedirectUri, StandardCharsets.UTF_8)
         + "&response_type=code"
         + "&scope=" + URLEncoder.encode("email profile", StandardCharsets.UTF_8)
         + "&access_type=online";
    }// 구글 로그인 URL

    public void processGoogle(String code, HttpServletRequest request, HttpServletResponse response) 
        throws IOException, InterruptedException {
        Map<String, String> tokenParams = Map.of(
            "code", code,
            "client_id", googleClientId,
            "client_secret", googleClientSecret,
            "redirect_uri", googleRedirectUri,
            "grant_type", "authorization_code"
        );
        StringBuilder tokenReqBody = new StringBuilder();
        for(Map.Entry<String, String> e : tokenParams.entrySet()) {
            if(tokenReqBody.length() > 0) tokenReqBody.append('&');
            tokenReqBody.append(URLEncoder.encode(e.getKey(), StandardCharsets.UTF_8))
            .append('=')
            .append(URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8));
        }
        HttpRequest tokenReq = HttpRequest.newBuilder()
            .uri(URI.create("https://oauth2.googleapis.com/token"))
            .header("Content-Type", "application/x-www-form-urlencoded")
            .POST(HttpRequest.BodyPublishers.ofString(tokenReqBody.toString()))
            .build();
        String tokenBody = httpClient.send(tokenReq, HttpResponse.BodyHandlers.ofString()).body();
        JsonNode tokenJson = objectMapper.readTree(tokenBody);
        String accessToken = tokenJson.get("access_token").asText();
       HttpRequest userReq = HttpRequest.newBuilder()
            .uri(URI.create("https://www.googleapis.com/oauth2/v2/userinfo"))
            .header("Authorization", "Bearer " + accessToken)
            .GET().build();
        JsonNode userJson = objectMapper.readTree(
            httpClient.send(userReq, HttpResponse.BodyHandlers.ofString()).body()
        );
        String providerId = userJson.get("id").asText();
        String email = userJson.get("email").asText();
        String name = userJson.has("name") ? userJson.get("name").asText() : "구글회원";
        loginOrJoin("GOOGLE", providerId, email, name, request, response);
    }

    private void loginOrJoin(String provider, String providerId, String email, String name, 
        HttpServletRequest request, HttpServletResponse response) {

            MemberVO member = memberMapper.findByProviderAndProviderId(provider, providerId);

            // 로컬로 가입된 회원인지 검사
            if(member == null) member = memberMapper.findByEmail(email);
            if(member == null) {
                member = new MemberVO();
                member.setMemberEmail(email);
                member.setMemberName(name);
                member.setProvider(provider);
                member.setProviderId(providerId);
                member.setMemberPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
                memberMapper.insertMemberOAuthMember(member);
            }
            UserDetails userDetails = memberUserDetailsService.loadUserByUsername(member.getMemberEmail());
            UsernamePasswordAuthenticationToken auth = 
                new UsernamePasswordAuthenticationToken(userDetails, userDetails.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(auth);
                new HttpSessionSecurityContextRepository()
                    .saveContext(SecurityContextHolder.getContext(), request, response); 
        }

}
