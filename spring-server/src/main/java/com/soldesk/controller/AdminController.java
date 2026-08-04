package com.soldesk.controller;

import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.soldesk.service.AdminService;
import com.soldesk.service.LearnService;
import com.soldesk.service.MemberService;
import com.soldesk.service.SuspendService;
import com.soldesk.vo.AnswerRequest;
import com.soldesk.vo.InquiryVO;
import com.soldesk.vo.MemberVO;
import com.soldesk.vo.PageBean;
import com.soldesk.vo.SignWordVO;

@Controller
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private MemberService memberService;

    // @Autowired
    // private BoardService boardService;

    @Autowired
    private SuspendService suspendService;

    @Autowired
    private LearnService learnService;

    @Autowired
    private AdminService adminService;

    @GetMapping("/main")
    public String dashboard(Model model, Authentication authentication) {

        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
        Date nowDate = new Date();
        String today = format.format(nowDate);
        int totalUsers = memberService.getMemberCount();
        int newUsersToday = memberService.newUserToday();

        // board 만들어지면 쿼리문 매핑해서 하기
        // int totalPosts = boardService.getBoardCount();
        // int newBoardToday = boardService.newBoardToday();

        // 주간 일별 추가 회원 수
        List<Integer> weeklySignups = memberService.getWeeklySignupCounts();
        // 주간 회원 수 max값
        int weeklyMax = Collections.max(weeklySignups);

        // 오류 신고 개수
        int errorCount = adminService.getErrorCount();
        model.addAttribute("todayLabel", today);
        model.addAttribute("totalUsers", totalUsers);
        // model.addAttribute("totalPosts", totalPosts);
        // model.addAttribute("newBoardToday", newBoardToday);
        model.addAttribute("newUsersToday", newUsersToday);
        model.addAttribute("weeklySignups", weeklySignups);
        model.addAttribute("weeklyMax", weeklyMax);
        model.addAttribute("errorCount", errorCount);
        return "admin/dashboard";
    }

    @GetMapping("/user/list")
    public String userList(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(required = false) String filterType,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "newest") String sort,
            Model model) {
        String role = null;
        String status = null;

        if (filterType != null && filterType.contains(":")) {
            String[] parts = filterType.split(":", 2);
            if ("role".equals(parts[0])) {
                role = parts[1];
            } else if ("status".equals(parts[0])) {
                status = parts[1];
            }
        }

        // 모든 회원
        int pageSize = 10;
        int count = memberService.adminGetMemberCount(role, status, keyword);
        PageBean pageBean = new PageBean(page, count, pageSize);
        List<MemberVO> members = memberService.getMemberList(pageBean.getCurrentPage(), pageSize, role, status, keyword,
                sort);
        model.addAttribute("pageBean", pageBean);
        model.addAttribute("userList", members);
        model.addAttribute("filterType", filterType);
        return "admin/userList";
    }

    @GetMapping("/user/info")
    public String userInfo(Model model,
            @RequestParam int memberId) {
        MemberVO member = memberService.getMemberInfo(memberId);
        model.addAttribute("member", member);
        return "admin/userInfo";
    }

    @PostMapping("/user/stop")
    public String userStop(@RequestParam int memberId,
            @RequestParam String suspendDays,
            @RequestParam String reason,
            Authentication authentication) {

        String adminEmail = authentication.getName();
        MemberVO admin = memberService.getMemberByEmail(adminEmail);
        int adminId = admin.getMemberId();

        suspendService.suspendMember(memberId, suspendDays, reason, adminId);
        memberService.suspendMember(memberId);
        return "redirect:/admin/user/info?memberId=" + memberId;
    }

    // 연쇄 삭제는 회의 후 결정
    @PostMapping("/user/delete")
    public String userDelete(@RequestParam int memberId) {

        memberService.deleteMember(memberId);

        return "redirect:/admin/user/list";
    }

    @GetMapping("/word/update")
    public String wordList(Model model,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(required = false) String keyword) {
        int pageSize = 20;
        int count = learnService.getWordCount(keyword);
        PageBean pageBean = new PageBean(page, count, pageSize);

        int offset = (page - 1) * pageSize;
        model.addAttribute("words", learnService.getWordList(keyword, offset, pageSize));
        model.addAttribute("pageBean", pageBean);
        return "admin/wordUpdate";
    }

    @GetMapping("/word/info")
    public String wordInfo(Model model,
            @RequestParam int signWordId) {
        SignWordVO word = learnService.getDictWordDetailById(signWordId);
        model.addAttribute("word", word);

        return "admin/wordInfo";
    }

    @PostMapping("/word/update")
    public String wordUpdate(@RequestParam int signWordId,
            @RequestParam String signWordName,
            @RequestParam String choseong,
            @RequestParam String signWordVideo,
            @RequestParam String signWordThumbnail,
            @RequestParam String description) {
        learnService.updateWord(signWordId, signWordName, choseong, signWordVideo, signWordThumbnail, description);
        return "redirect:/admin/word/info?signWordId=" + signWordId;
    }

    @GetMapping("/inquiry")
    public String inquiryForm(
            @RequestParam(value = "category", required = false, defaultValue = "ERROR_REPORT") String category,
            @RequestParam(value = "status", required = false, defaultValue = "WAIT") String status,
            Model model) {

        List<InquiryVO> inquiryList = adminService.getInquiryList(category, status);
        int waitCount = adminService.getStatusCount(category, "WAIT");
        int processingCount = adminService.getStatusCount(category, "PROCESSING");

        model.addAttribute("inquiryList", inquiryList);
        model.addAttribute("waitCount", waitCount);
        model.addAttribute("processingCount", processingCount);
        model.addAttribute("currentStatus", status);
        model.addAttribute("currentCategory", category);
        return "admin/error";
    }

    @PostMapping("/inquiry/answer")
    @ResponseBody
    public Map<String, Object> submitAnswer(@RequestBody AnswerRequest request,
            Authentication authentication) {
        MemberVO admin = memberService.getMemberByEmail(authentication.getName());
        Long adminMemberId = (long) admin.getMemberId();
        int sendToUserId = (int) adminService.findUserIdByInquiry(request.getInquiryId());
        boolean result = adminService.answerInquiry(
                request.getInquiryId(), request.getAnswerContent(), adminMemberId, sendToUserId);
        return Map.of("success", result);
    }

}
