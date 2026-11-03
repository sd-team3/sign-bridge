package com.soldesk.controller;

import java.io.IOException;
import java.util.Map;
import javax.servlet.http.*;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.fasterxml.jackson.databind.JsonNode;
import com.soldesk.service.*;
import com.soldesk.service.SignLearningApiService.ApiException;
import com.soldesk.vo.MemberVO;

@Controller
@RequestMapping("/exam/words")
public class WordExamController {
    private final WordExamService exams;
    private final SignLearningApiService learning;
    private final MemberService members;

    public WordExamController(WordExamService exams, SignLearningApiService learning, MemberService members) {
        this.exams = exams; this.learning = learning; this.members = members;
    }

    @ModelAttribute
    public void noCache(HttpServletResponse response) { response.setHeader("Cache-Control", "private, no-store"); }

    private int member() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal()))
            throw new ApiException(401, "로그인 후 시험을 이용해 주세요.");
        MemberVO member = members.getMemberByEmail(auth.getName());
        if (member == null) throw new ApiException(401, "로그인 정보를 확인해 주세요.");
        return member.getMemberId();
    }

    @GetMapping
    public String page() {
        try { member(); } catch (ApiException ex) { return "redirect:/member/login"; }
        return "exam/words";
    }

    @GetMapping("/api/history") @ResponseBody
    public JsonNode history() { return exams.history(member()); }

    @PostMapping("/api/start") @ResponseBody
    public JsonNode start(@RequestParam("mode") String mode,
            @RequestParam(value="chapter", defaultValue="") String chapter,
            @RequestParam(value="review", defaultValue="") String review) {
        return exams.start(member(), mode, chapter, review);
    }

    @GetMapping("/api/{id}") @ResponseBody
    public JsonNode get(@PathVariable("id") String id) { return exams.get(id, member()); }

    @GetMapping("/api/{id}/questions/{number}/video")
    public void video(@PathVariable("id") String id, @PathVariable("number") int number,
            @RequestHeader(value="Range", required=false) String range, HttpServletResponse response) throws IOException {
        response.setHeader("Cache-Control", "private, no-store");
        learning.reference(exams.referenceWord(id, member(), number), range, response);
    }

    @PostMapping("/api/{id}/choice") @ResponseBody
    public JsonNode choice(@PathVariable("id") String id, @RequestParam("number") int number, @RequestParam("answer") String answer) {
        return exams.choice(id, member(), number, answer);
    }

    @PostMapping(value="/api/{id}/motion", consumes="multipart/form-data") @ResponseBody
    public JsonNode motion(@PathVariable("id") String id, @RequestParam("number") int number,
            @RequestParam("attempt_id") String attempt, @RequestParam("video") MultipartFile video) {
        return exams.motion(id, member(), number, attempt, video);
    }

    @PostMapping("/api/{id}/skip") @ResponseBody
    public JsonNode skip(@PathVariable("id") String id, @RequestParam("number") int number) { return exams.skip(id, member(), number); }

    @PostMapping("/api/{id}/finish") @ResponseBody
    public JsonNode finish(@PathVariable("id") String id) { return exams.finish(id, member()); }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Map<String,String>> error(ApiException ex) {
        return ResponseEntity.status(ex.getStatus()).body(Map.of("message", ex.getMessage()));
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String,String>> databaseError() {
        return ResponseEntity.status(503).body(Map.of("message", "시험 기록 저장소에 연결하지 못했습니다. 잠시 후 다시 시도해 주세요."));
    }
}
