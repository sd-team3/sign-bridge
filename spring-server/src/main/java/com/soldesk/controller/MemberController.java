package com.soldesk.controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.soldesk.service.BoardService;
import com.soldesk.service.CommentService;
import com.soldesk.service.LearningHistoryService;
import com.soldesk.service.MemberService;
import com.soldesk.service.MemberSettingService;
import com.soldesk.service.ChainRoomService;
import com.soldesk.service.OverviewStatsService;
import com.soldesk.service.WrongAnswerService;
import com.soldesk.util.SecurityUtil;
import com.soldesk.vo.MemberVO;
import com.soldesk.vo.OverviewStatsVO;
import com.soldesk.service.FavoriteService;
import com.soldesk.vo.FavoriteWordVO;

@Controller
@RequestMapping("/member")
public class MemberController {
    @Autowired
    private MemberService memberService;
    @Autowired
    private SecurityUtil securityUtil;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private BoardService boardService;
    @Autowired
    private CommentService commentService;
    @Autowired
    private WrongAnswerService wrongAnswerService;
    @Autowired
    private LearningHistoryService learningHistoryService;
    @Autowired
    private OverviewStatsService overviewStatsService;
    @Autowired
    private FavoriteService favoriteService;
    @Autowired
    private MemberSettingService memberSettingService;
    @Autowired
    private ChainRoomService chainRoomService;

    @GetMapping("/join")
    public String join(@ModelAttribute("joinMember") MemberVO member) {
        return "member/join";
    }
    @PostMapping("/join")
    public String joinSubmit(@Valid @ModelAttribute("joinMember") 
        MemberVO member, BindingResult bindingResult) {
            if(bindingResult.hasErrors()) {
                bindingResult.getAllErrors().forEach(error -> 
                    System.out.println(error.toString())
                );
                return "member/join";
            }
            memberService.join(member);
            return "redirect:/member/login";
    }

    @GetMapping("/login")
    public String login() {
        return "member/login";
    }
    
    @GetMapping("/mypage")
    public String mypage(Model model) {
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if(currentMemberId == null) {
            return "redirect:/member/login";
        }
        MemberVO member = memberService.getMemberById(currentMemberId);
        model.addAttribute("member", member);
        OverviewStatsVO overviewStats = overviewStatsService.getOverviewStats(currentMemberId);
        model.addAttribute("overviewStats", overviewStats);
        List<String> offList = memberSettingService.getOffTypes(currentMemberId);
        model.addAttribute("offAlarmTypesCsv", "," + String.join(",", offList) + ",");
        return "member/mypage";
    }
    @PostMapping("/update")
    @ResponseBody
    public Map<String, Object> updateMember(@RequestParam int memberId, @RequestParam String memberName) {
        Map<String, Object> result = new HashMap<>();

        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if (currentMemberId == null || !currentMemberId.equals(memberId)) {
            result.put("success", false);
            result.put("message", "권한이 없습니다.");
            return result;
        }

        memberService.updateMemberName(memberId, memberName);
        result.put("success", true);
        return result;
    }

    @PostMapping("/passUpdate")
    @ResponseBody
    public Map<String, Object> updatePassword(@RequestParam String currentPassword, @RequestParam String newPassword) {
        Map<String, Object> result = new HashMap<>();
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if(currentMemberId == null) {
            result.put("success", false);
            result.put("message", false);
            return result;
        }

        MemberVO member = memberService.getMemberById(currentMemberId);
        if (!"LOCAL".equals(member.getProvider())) {
            result.put("success", false);
            result.put("message", "소셜 로그인 계정은 비밀번호를 변경할 수 없습니다.");
            return result;
        }

        if (!passwordEncoder.matches(currentPassword, member.getMemberPassword())) {
            result.put("success", false);
            result.put("message", "현재 비밀번호가 일치하지 않습니다.");
            return result;
        }

        String encodedNewPassword = passwordEncoder.encode(newPassword);
        memberService.updatePassword(currentMemberId, encodedNewPassword);
        result.put("success", true);
        return result;
    }

    @PostMapping("/delete")
    @ResponseBody
    public Map<String, Object> deleteMember(@RequestParam(required = false) String password,
        HttpServletRequest request) {
        
        Map<String, Object> result = new HashMap<>();
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        if(currentMemberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }
        
        MemberVO member = memberService.getMemberById(currentMemberId);
        
        if("LOCAL".equals(member.getProvider())) {
            if(password == null || !passwordEncoder.matches(password, member.getMemberPassword())) {
                result.put("success", false);
                result.put("message", "비밀번호가 일치하지 않습니다.");
                return result;
            }
        }
        memberService.deleteMember(currentMemberId);

        request.getSession().invalidate();
        SecurityContextHolder.clearContext();
        
        result.put("success", true);
        return result;
    }

    @GetMapping("/mypage/board")
    @ResponseBody
    public Map<String, Object> myPosts(@RequestParam(defaultValue = "1") int page,
                                        @RequestParam(required = false) String category) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) { result.put("success", false); return result; }
        result = boardService.getBoardsByMember(memberId, category, page);
        result.put("success", true);
        return result;
    }

    @GetMapping("/mypage/comment")
    @ResponseBody
    public Map<String, Object> myComments(@RequestParam(defaultValue = "1") int page,
                                        @RequestParam(required = false) String category) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) { result.put("success", false); return result; }
        result = commentService.getCommentsByMember(memberId, category, page);
        result.put("success", true);
        return result;
    }

    @GetMapping("/mypage/wronganswer")
    @ResponseBody
    public Map<String, Object> myWrongAnswers(@RequestParam(defaultValue = "1") int page, @RequestParam(required = false) String category) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) {
            result.put("success", false);
            return result;
        }
        result = wrongAnswerService.getWrongAnswersByMember(memberId, category, page);
        result.put("success", true);
        return result;
    }

    @GetMapping("/mypage/history/jamo")
    @ResponseBody
    public Map<String, Object> myJamoHistory(@RequestParam(defaultValue = "1") int page, @RequestParam(required = false) String category) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) { result.put("success", false); return result; }
        result = learningHistoryService.getJamoHistoryByMember(memberId, category, page);
        result.put("success", true);
        return result;
    }

    @GetMapping("/mypage/history/word")
    @ResponseBody
    public Map<String, Object> myWordHistory(@RequestParam(defaultValue = "1") int page, @RequestParam(required = false) String category) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) { result.put("success", false); return result; }
        result = learningHistoryService.getWordHistoryByMember(memberId, category, page);
        result.put("success", true);
        return result;
    }

    @GetMapping("/mypage/history/chain")
    @ResponseBody
    public Map<String, Object> myChainHistory(@RequestParam(defaultValue = "1") int page) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) { result.put("success", false); return result; }
        result = chainRoomService.myChainHistory(memberId, page);
        result.put("success", true);
        return result;
    }

    @GetMapping("/mypage/history/chain/{roomId}")
    @ResponseBody
    public Map<String, Object> myChainHistoryDetail(@org.springframework.web.bind.annotation.PathVariable long roomId) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) { result.put("success", false); return result; }
        try {
            result = chainRoomService.chainHistoryDetail(roomId, memberId);
            result.put("success", true);
        } catch (IllegalStateException e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/favorite/toggle")
    @ResponseBody
    public Map<String, Object> toggleFavorite(@RequestParam Integer signWordId) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }
        boolean favorited = favoriteService.toggleFavorite(memberId, signWordId);
        result.put("success", true);
        result.put("favorited", favorited);
        return result;
    }

    @GetMapping("/mypage/favorite")
    @ResponseBody
    public Map<String, Object> getMyFavorites(@RequestParam(defaultValue = "1") int page) {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        int pageSize = 9;
        List<FavoriteWordVO> favorites = favoriteService.getFavorites(memberId, page, pageSize);
        int total = favoriteService.countFavorites(memberId);
        int totalPages = (int) Math.ceil((double) total / pageSize);

        result.put("success", true);
        result.put("favorites", favorites);
        result.put("currentPage", page);
        result.put("totalPages", Math.max(totalPages, 1));
        return result;
    }
    @GetMapping("/favorite/ids")
    @ResponseBody
    public Map<String, Object> getFavoriteIds() {
        Integer memberId = securityUtil.getCurrentMemberId();
        Map<String, Object> result = new HashMap<>();
        if (memberId == null) {
            result.put("success", true);
            result.put("ids", new ArrayList<Integer>());
            return result;
        }
        result.put("success", true);
        result.put("ids", favoriteService.getFavoriteIds(memberId));
        return result;
    }
    @PostMapping("/alarm/update")
    @ResponseBody
    public Map<String, Object> updateAlarm(@RequestParam String notificationType, @RequestParam boolean on) {
        Map<String, Object> result = new HashMap<>();
        Integer memberId = securityUtil.getCurrentMemberId();
        if (memberId == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return result;
        }
        memberSettingService.setAlarm(memberId, notificationType, on);
        result.put("success", true);
        return result;
    }


}
