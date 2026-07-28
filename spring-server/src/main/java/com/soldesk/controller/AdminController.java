package com.soldesk.controller;

import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.soldesk.service.AdminService;
import com.soldesk.vo.AnswerRequest;
import com.soldesk.vo.InquiryVO;

@Controller
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private AdminService adminService;

    @GetMapping("/inquiry")
    public String inquiryForm(@RequestParam(value = "category",
                                            required = false,
                                            defaultValue = "ERROR_REPORT") String category,
                               @RequestParam(value = "status",
                                            required = false,
                                            defaultValue = "WAIT") String status,
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
                                             HttpSession session) {
        Long adminMemberId = (Long) session.getAttribute("memberId");
        boolean result = adminService.answerInquiry(
                request.getInquiryId(), request.getAnswerContent(), adminMemberId);
        return Map.of("success", result);
    }
}