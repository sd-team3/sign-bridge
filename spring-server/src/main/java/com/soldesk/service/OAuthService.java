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
import javax.servlet.http.HttpSession;

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
    // google OAuth
    @Value("${google.client-id}")
    private String googleClientId;
    @Value("${google.client-secret}")
    private String googleClientSecret;
    @Value("${google.redirect-uri}")
    private String googleRedirectUri;

    // naver OAuth
    @Value("${naver.client-id}")
    private String naverClientId;
    @Value("${naver.client-secret}")
    private String naverClientSecret;
    @Value("${naver.redirect-uri}")
    private String naverRedirectUri;

    // kakao OAuth
    @Value("${kakao.client-id}")
    private String kakaoClientId;
    @Value("${kakao.client-secret}")
    private String kakaoClientSecret;
    @Value("${kakao.redirect-uri}")
    private String kakaoRedirectUri;

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

    public String getNaverAuthUrl(HttpSession session) {
        String state = UUID.randomUUID().toString(); // CSRF 방지용 state 값
        session.setAttribute("naverState", state);
        return "https://nid.naver.com/oauth2.0/authorize"
         + "?client_id=" + naverClientId
         + "&redirect_uri=" + URLEncoder.encode(naverRedirectUri, StandardCharsets.UTF_8)
         + "&response_type=code"
         + "&state=" + state;   // CSRF 위조 방지 파라미터
    }// 네이버 로그인 URL

    public String getKakaoAuthUrl() {
        return "https://kauth.kakao.com/oauth/authorize"
        + "?client_id=" + kakaoClientId
        + "&redirect_uri=" + URLEncoder.encode(kakaoRedirectUri, StandardCharsets.UTF_8)
        + "&response_type=code";
    }


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

    public void processNaver(String code, String state, HttpServletRequest request, HttpServletResponse response) 
        throws IOException, InterruptedException {
        String savedState = (String)request.getSession().getAttribute("naverState"); // 비교할 state

        // state 값 비교(위조 가능성 배제)
        if(!state.equals(savedState)) throw new IllegalStateException("state 값이 불일치합니다."); // state (파라미터)
        
        Map<String, String> tokenParams = Map.of( // 차이 파라미터
            "code", code,
            "client_id", naverClientId,
            "client_secret", naverClientSecret,
            "redirect_uri", naverRedirectUri,
            "grant_type", "authorization_code",
            "state", state
        );
        StringBuilder tokenReqBody = new StringBuilder();
        for(Map.Entry<String, String> e : tokenParams.entrySet()) {
            if(tokenReqBody.length() > 0) tokenReqBody.append('&');
            tokenReqBody.append(URLEncoder.encode(e.getKey(), StandardCharsets.UTF_8))
            .append('=')
            .append(URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8));
        }
        HttpRequest tokenReq = HttpRequest.newBuilder()
            .uri(URI.create("https://nid.naver.com/oauth2.0/token")) // 차이 1
            .header("Content-Type", "application/x-www-form-urlencoded")
            .POST(HttpRequest.BodyPublishers.ofString(tokenReqBody.toString()))
            .build();
        String tokenBody = httpClient.send(tokenReq, HttpResponse.BodyHandlers.ofString()).body();
        JsonNode tokenJson = objectMapper.readTree(tokenBody);
        String accessToken = tokenJson.get("access_token").asText();
       HttpRequest userReq = HttpRequest.newBuilder()
            .uri(URI.create("https://openapi.naver.com/v1/nid/me")) // 차이 2
            .header("Authorization", "Bearer " + accessToken)
            .GET().build();
        JsonNode userJson = objectMapper.readTree(
            httpClient.send(userReq, HttpResponse.BodyHandlers.ofString()).body()
        );

        JsonNode userInfo = userJson.get("response");
        String providerId = userInfo.get("id").asText();
        String email = userInfo.get("email").asText();
        String name = userInfo.has("name") ? userInfo.get("name").asText() : "네이버회원"; // 차이 3
        loginOrJoin("NAVER", providerId, email, name, request, response); // 차이 4
    }

    public void processKakao(String code, HttpServletRequest request, HttpServletResponse response) 
        throws IOException, InterruptedException {
        Map<String, String> tokenParams = Map.of( // 차이 파라미터
            "code", code,
            "client_id", kakaoClientId,
            "client_secret", kakaoClientSecret,
            "redirect_uri", kakaoRedirectUri,
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
            .uri(URI.create("https://kauth.kakao.com/oauth/token")) // 차이 1
            .header("Content-Type", "application/x-www-form-urlencoded")
            .POST(HttpRequest.BodyPublishers.ofString(tokenReqBody.toString()))
            .build();
        String tokenBody = httpClient.send(tokenReq, HttpResponse.BodyHandlers.ofString()).body();
        JsonNode tokenJson = objectMapper.readTree(tokenBody);
        String accessToken = tokenJson.get("access_token").asText();
       HttpRequest userReq = HttpRequest.newBuilder()
            .uri(URI.create("https://kapi.kakao.com/v2/user/me")) // 차이 2
            .header("Authorization", "Bearer " + accessToken)
            .GET().build();
        JsonNode userJson = objectMapper.readTree(
            httpClient.send(userReq, HttpResponse.BodyHandlers.ofString()).body()
        );
        String providerId = userJson.get("id").asText();

        JsonNode account = userJson.get("kakao_account");

        // 이메일 제공 동의하지 않을 시 예외
        if(account == null || !account.has("email")) {
            throw new IllegalStateException("이메일 제공 동의가 필요합니다.");
        }

        String email = account.get("email").asText();
        String name = account.has("profile") && account.get("profile").has("nickname")
             ? account.get("profile").get("nickname").asText() : "카카오회원"; // 차이 3
        loginOrJoin("KAKAO", providerId, email, name, request, response); // 차이 4
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
