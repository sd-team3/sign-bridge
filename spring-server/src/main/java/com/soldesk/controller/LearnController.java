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

    // word 파라미터가 없을 때만 목록으로 진입 (상세 매핑과 경로 겹침 방지)
    @GetMapping(value = "/dict", params = "!word")
    public String dict(Model model) {
        // 초기 진입 시에는 필터/검색 없이 조회수 높은 순으로 노출
        model.addAttribute("words", learnService.getDictWords(null, null));
        return "learn/dict";
    }

    // /learn/dict?word=사과 형태로 진입 시 상세
    @GetMapping(value = "/dict", params = "word")
    public String dictDetail(@RequestParam("word") String word, Model model) {
        learnService.increaseViewCount(word);
        model.addAttribute("word", learnService.getDictWordDetail(word));
        return "learn/dict";
    }

    // jp안거치고 json으로 리턴값 바로받아서 파라미터 없어도 에러 x
    @GetMapping("/dict/search")
    @ResponseBody
    public List<SignWordVO> dictSearch(
            @RequestParam(value = "choseong", required = false) String choseong,
            @RequestParam(value = "keyword", required = false) String keyword) {
        return learnService.getDictWords(choseong, keyword);
    }

    // 초기 진입 시 히어로 영역에 랜덤 재생할 단어
    @GetMapping("/dict/random")
    @ResponseBody
    public SignWordVO dictRandom() {
        return learnService.getRandomDictWord();
    }

    // 검색/필터/수어인식으로 선택된 단어의 영상을 페이지 새로고침 없이 가져오기 (조회수 증가 포함)
    @GetMapping("/dict/video")
    @ResponseBody
    public SignWordVO dictVideo(@RequestParam("word") String word) {
        SignWordVO detail = learnService.getDictWordDetail(word);
        if (detail != null) {
            learnService.increaseViewCount(word);
        }
        return detail;
    }

    // 국립수어사전 원본 영상의 핫링크(Referer 체크) 우회용 프록시
    // 프론트 <video src>가 외부 URL을 직접 부르면 403이 뜨기 때문에
    // 서버가 대신 요청해서 스트림을 그대로 전달한다
    @GetMapping("/dict/video-proxy")
    public void videoProxy(@RequestParam("url") String url, HttpServletResponse response) throws IOException {
        learnService.proxyVideo(url, response);
    }

    // dict 상세 모달에서 오류 신고 접수 -> inquiry(관리자 확인용) + board(공개 게시판) 둘 다 등록
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

        // 수정 - 코드값은 DB에, 한글 라벨은 title에만 쓰도록 분리
        String title = "(" + word + ") 오류 신고";
        String body = (content == null || content.isBlank())
                ? "사용자가 해당 단어의 오류를 신고했습니다."
                : content;

        // board 먼저 만들고 생성된 boardId를 inquiry에 같이 넣어서 서로 연결시킴
        BoardVO board = new BoardVO();
        board.setMemberId(member.getMemberId());
        board.setCategoryIdx("REPORT");
        board.setBoardTitle(title);
        board.setBoardContent(body);
        board.setNoticeYn("Y");
        boardService.writeBoard(board); // board.getBoardId()에 생성된 id 채워짐

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
