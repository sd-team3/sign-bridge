package com.soldesk.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.PathVariable;

import com.soldesk.service.ExamService;
import com.soldesk.service.MemberService;
import com.soldesk.vo.ExamQuestionVO;
import com.soldesk.vo.ExamResultVO;
import com.soldesk.vo.MemberVO;

@Controller
@RequestMapping("/exam")
public class ExamController {

    @Autowired
    private ExamService examService;

    @Autowired
    private MemberService memberService;

    private int getCurrentMemberId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            return -1;
        }
        String email = auth.getName();
        MemberVO member = memberService.getMemberByEmail(email);
        return member != null ? member.getMemberId() : -1;
    }

    @GetMapping("/setup")
    public String setup() {
        if (getCurrentMemberId() == -1) {
            return "redirect:/member/login";
        }
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
    public String result(@RequestParam Long sessionId, Model model) {
        ExamResultVO result = examService.getResult(sessionId);
        model.addAttribute("session", result.getSession());
        model.addAttribute("wrongList", result.getWrongList());
        return "exam/result";
    }

    /** 시험 시작: test_session 생성 + 문제 목록 HttpSession에 저장 */
    @PostMapping("/api/start")
    @ResponseBody
    public Map<String, Object> start(@RequestParam String mode, @RequestParam int count, HttpSession session) {
        int memberId = getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == -1) {
            result.put("error", "unauthorized");
            return result;
        }
        Long sessionId = examService.startSession(memberId, mode, count, session);
        result.put("sessionId", sessionId);
        return result;
    }

    @GetMapping("/api/questions")
    @ResponseBody
    public List<ExamQuestionVO> questions(@RequestParam Long sessionId, @RequestParam String phase, HttpSession session) {
        return examService.getPhaseQuestions(sessionId, phase, session);
    }

    @PostMapping("/api/{sessionId}/answer")
    @ResponseBody
    public Map<String, Object> answer(
            @PathVariable Long sessionId,
            @RequestParam Long signWordId,
            @RequestParam int questionNo,
            @RequestParam String userAnswer,
            @RequestParam boolean isCorrect) {
        examService.submitAnswer(sessionId, signWordId, questionNo, userAnswer, isCorrect);
        Map<String, Object> result = new HashMap<>();
        result.put("ok", true);
        return result;
    }

    @PostMapping("/api/{sessionId}/finish")
    @ResponseBody
    public Map<String, Object> finish(
            @PathVariable Long sessionId,
            @RequestParam int correctCount,
            @RequestParam int totalCount) {
        examService.finishSession(sessionId, correctCount, totalCount);
        Map<String, Object> result = new HashMap<>();
        result.put("ok", true);
        return result;
    }
}