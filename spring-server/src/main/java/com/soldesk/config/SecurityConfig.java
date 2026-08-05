package com.soldesk.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;

import com.soldesk.security.MemberUserDetailsService;

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Autowired
    private MemberUserDetailsService memberUserDetailsService;

    @Bean
    public SecurityFilterChain filterChain(
        HttpSecurity http, DaoAuthenticationProvider authenticationProvider) throws Exception {
        http.csrf(csrf -> csrf
            .ignoringRequestMatchers(
                new AntPathRequestMatcher("/api/sign/**"),
                new AntPathRequestMatcher("/exam/api/**")
            )
        ).authorizeHttpRequests(auth -> auth
            .requestMatchers(
                new AntPathRequestMatcher("/ws/**")
            ).permitAll()
            .requestMatchers( // 어드민 접근 영역
                new AntPathRequestMatcher("/admin/**")
            ).hasRole("ADMIN")
            .requestMatchers( // 로그인 시 접근 영역
                new AntPathRequestMatcher("/member/info"),
                new AntPathRequestMatcher("/member/update"),
                new AntPathRequestMatcher("/member/delete"),
                new AntPathRequestMatcher("/board/write"),
                new AntPathRequestMatcher("/comment/**")
            ).authenticated().anyRequest().permitAll()
        ).formLogin(form -> form
            .loginPage("/member/login")
            .loginProcessingUrl("/member/login")
            .usernameParameter("memberEmail")
            .passwordParameter("memberPassword")
            .defaultSuccessUrl("/", true)
            .failureHandler((request, response, exception) -> {
                String error = (exception instanceof DisabledException) ? "suspended" : "badCredentials";
                response.sendRedirect(request.getContextPath() + "/member/login?error=" + error);
            })
            .permitAll()
        ).logout(logout -> logout
            .logoutUrl("/member/logout")
            .logoutSuccessUrl("/")
            .permitAll()
        ).authenticationProvider(authenticationProvider);
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    } // 비밀번호 암호화

    @Bean
    public DaoAuthenticationProvider authenticationProvider(PasswordEncoder passwordEncoder) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(memberUserDetailsService);
        provider.setPasswordEncoder(passwordEncoder);
        return provider;
    } // 사용자 인증을 처리
    
}
