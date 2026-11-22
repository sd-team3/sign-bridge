package com.soldesk.controller;

import java.io.IOException;
import java.util.List;

import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.soldesk.service.LearnService;
import com.soldesk.vo.SignWordVO;
import com.soldesk.service.BoardService;

import java.util.Map;
import org.springframework.web.bind.annotation.PostMapping;

import com.soldesk.security.CustomUserDetail;
import com.soldesk.service.AdminService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import com.soldesk.service.MemberService;
import com.soldesk.vo.MemberVO;
import com.soldesk.vo.BoardVO;

@Controller
@RequestMapping("/learn")
public class LearnController {

    @Autowired
    private LearnService learnService;

    @Autowired
    private AdminService adminService;

    @Autowired
    private MemberService memberService;

    @Autowired
    private BoardService boardService;

    @GetMapping("")
    public String main(Model model, @AuthenticationPrincipal CustomUserDetail userDetails) {
        model.addAttribute("jamoCount", learnService.countAll());
        if (userDetails != null) {
            model.addAttribute("memberName", userDetails.getMemberName());
            model.addAttribute("lastLearningLabel", learnService.getLastLearningLabel(userDetails.getMemberId()));
        }
        return "learn/main";
    }

    @GetMapping("/jamo")
    public String jamo(Model model) {
        model.addAttribute("consonants", learnService.getConsonants());
        model.addAttribute("vowels", learnService.getVowels());
        return "learn/jamo";
    }


    @GetMapping(value = "/dict", params = "!word")
    public String dict(Model model) {

        model.addAttribute("words", learnService.getDictWords(null, null));
        return "learn/dict";
    }


    @GetMapping(value = "/dict", params = "word")
    public String dictDetail(@RequestParam("word") String word, Model model) {
        learnService.increaseViewCount(word);
        model.addAttribute("word", learnService.getDictWordDetail(word));
        return "learn/dict";
    }


    @GetMapping("/dict/search")
    @ResponseBody
    public List<SignWordVO> dictSearch(
            @RequestParam(value = "choseong", required = false) String choseong,
            @RequestParam(value = "keyword", required = false) String keyword) {
        return learnService.getDictWords(choseong, keyword);
    }


    @GetMapping("/dict/random")
    @ResponseBody
    public SignWordVO dictRandom() {
        return learnService.getRandomDictWord();
    }


    @GetMapping("/dict/video")
    @ResponseBody
    public SignWordVO dictVideo(@RequestParam("word") String word) {
        SignWordVO detail = learnService.getDictWordDetail(word);
        if (detail != null) {
            learnService.increaseViewCount(word);
        }
        return detail;
    }




    @GetMapping("/dict/video-proxy")
    public void videoProxy(@RequestParam("url") String url, HttpServletResponse response) throws IOException {
        learnService.proxyVideo(url, response);
    }


    @PostMapping("/dict/report")
    @ResponseBody
    public Map<String, Object> reportWord(@RequestParam("word") String word,
            @RequestParam(value = "category", required = false, defaultValue = "기타") String category,
            @RequestParam(value = "content", required = false) String content,
            Authentication authentication) {
        if (authentication == null) {
            return Map.of("success", false, "message", "로그인이 필요합니다.");
        }

        String email = authentication.getName();
        MemberVO member = memberService.getMemberByEmail(email);
        if (member == null) {
            return Map.of("success", false, "message", "로그인이 필요합니다.");
        }
        Long memberId = (long) member.getMemberId();


        String title = "(" + word + ") 오류 신고";
        String body = (content == null || content.isBlank())
                ? "사용자가 해당 단어의 오류를 신고했습니다."
                : content;


        BoardVO board = new BoardVO();
        board.setMemberId(member.getMemberId());
        board.setCategoryIdx("REPORT");
        board.setBoardTitle(title);
        board.setBoardContent(body);
        board.setNoticeYn("Y");
        boardService.writeBoard(board);

        adminService.createInquiry(memberId, category, title, body, board.getBoardId());

        return Map.of("success", true);

    }

    private String toErrorTypeLabel(String code) {
        switch (code) {
            case "ACTION_RECOGNITION":
                return "동작 인식 오류";
            case "VIDEO_PLAYBACK":
                return "영상 재생 오류";
            case "TRANSLATION":
                return "번역 · 뜻풀이 오류";
            case "UI_BUG":
                return "화면 · 디자인 오류";
            case "ETC":
                return "기타";
            default:
                return code;
        }
    }

}
