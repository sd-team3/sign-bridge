package com.soldesk.controller;

import java.util.List;
import java.util.Map;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.soldesk.service.AdminService;
import com.soldesk.service.BoardSearchService;
import com.soldesk.service.CommentService;
import com.soldesk.service.BoardService;
import com.soldesk.service.MemberService;
import com.soldesk.util.SecurityUtil;
import com.soldesk.vo.BoardVO;
import com.soldesk.vo.MemberVO;
import com.soldesk.vo.PageBean;

@Controller
@RequestMapping("/board")
public class BoardController {

    @Autowired
    private MemberService memberService;
    @Autowired
    private BoardService boardService;
    @Autowired
    private BoardSearchService boardSearchService;
    @Autowired
    private CommentService commentService;
    @Autowired
    private SecurityUtil securityUtil;
    @Autowired
    private AdminService adminService;

    @GetMapping("/list")
    public String listBoard(@RequestParam(required = false) String category, @RequestParam(defaultValue = "1") int page,
            Model model) {
        int boardCnt = boardService.getCategoryBoardCount(category);
        int count = 6;
        PageBean pageBean = new PageBean(page, boardCnt, count);
        List<BoardVO> list = boardService.getBoardByCategory(category, page, count);

        model.addAttribute("boards", list);
        if (category != null)
            model.addAttribute("category", category);
        model.addAttribute("pageBean", pageBean);

        // 게시글 현황 출력용
        Map<String, Object> boardState = boardService.getBoardState();
        if (boardState != null)
            model.addAllAttributes(boardState);

        return "board/list";
    }

    @GetMapping("/write")
    public String writeBoard(Model model) {
        model.addAttribute("isAdmin", securityUtil.isAdmin());
        return "board/write";
    }

    // /board/report -> 오류신고 전용 작성 화면
    @GetMapping("/report")
    public String reportBoard() {
        return "board/report";
    }

    // REPORT 카테고리면 board 등록 후 inquiry에도 같이 넣어줌
    @PostMapping("/write")
    public String writeSubmit(@ModelAttribute BoardVO board) {
        String memberEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        MemberVO member = memberService.getMemberByEmail(memberEmail);

        boolean isNotice = "NOTICE".equals(board.getCategoryIdx());
        if(isNotice && !securityUtil.isAdmin()) {
            throw new AccessDeniedException("공지사항은 관리자만 작성할 수 있습니다.");
        }
        board.setMemberId(member.getMemberId());
        board.setNoticeYn(isNotice ? "N" : "Y");
        boardService.writeBoard(board); // 여기서 board.getBoardId()에 새 id 채워짐

        // 오류신고 게시글이면 관리자 페이지에서도 확인할 수 있게 inquiry 같이 생성
        if ("REPORT".equals(board.getCategoryIdx())) {
            adminService.createInquiry(
                    (long) member.getMemberId(),
                    "ERROR_REPORT",
                    board.getBoardTitle(),
                    board.getBoardContent(),
                    board.getBoardId());
        }

        String redirectUrl = "redirect:/board/list";
        return board.getCategoryIdx() != null ? redirectUrl + "?category=" + board.getCategoryIdx() : redirectUrl;
    }

    @GetMapping("/info")
    public String infoBoard(@RequestParam int boardId, Model model, HttpServletRequest request,
            HttpServletResponse response) {
        Map<String, Object> boardState = boardService.getBoardState();
        if (boardState != null)
            model.addAllAttributes(boardState);

        String cookieName = "viewed_" + boardId;
        boolean alreadyViewed = false;

        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie c : cookies) {
                if (c.getName().equals(cookieName)) {
                    alreadyViewed = true;
                    break;
                }
            }
        }

        if (!alreadyViewed) {
            boardService.increaseViewCount(boardId);

            Cookie newCookie = new Cookie(cookieName, "true");
            newCookie.setMaxAge(60 * 60 * 24); // 쿠키 만료 시간: 24시간
            newCookie.setPath("/");
            response.addCookie(newCookie);
        }

        BoardVO board = boardService.getBoardByBoardId(boardId);
        model.addAttribute("board", board);
        model.addAttribute("currentMemberId", securityUtil.getCurrentMemberId());

        return "board/info";
    }

    @GetMapping("/update")
    public String updateBoard(@RequestParam int boardId, Model model) {
        BoardVO board = boardService.getBoardByBoardId(boardId);
        model.addAttribute("board", board);
        return "board/update";
    }

    @PostMapping("/update")
    public String updateSubmit(@ModelAttribute BoardVO board) {
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        BoardVO original = boardService.getBoardByBoardId(board.getBoardId());

        if (currentMemberId == null || original == null || !currentMemberId.equals(original.getMemberId())) {
            throw new AccessDeniedException("수정 권한이 없습니다.");
        }

        board.setMemberId(original.getMemberId());
        boardService.updateBoard(board);
        return "redirect:/board/info?boardId=" + board.getBoardId();
    }

    @PostMapping("/delete")
    public String deleteBoard(@RequestParam int boardId) {
        Integer currentMemberId = securityUtil.getCurrentMemberId();
        BoardVO original = boardService.getBoardByBoardId(boardId);

        boolean isOwner = currentMemberId != null && original != null
                && currentMemberId.equals(original.getMemberId());

        if (original == null || !(isOwner || securityUtil.isAdmin())) {
            throw new AccessDeniedException("삭제 권한이 없습니다.");
        }

        commentService.deleteAllCommentsByBoardId(boardId);
        boardService.deleteBoard(boardId);
        return "redirect:/board/list";
    }

    @GetMapping("/search")
    public String searchBoard(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page, Model model) {

        Map<String, Object> boardState = boardService.getBoardState();
        if (boardState != null)
            model.addAllAttributes(boardState);

        if (keyword == null || keyword.isBlank()) {
            model.addAttribute("keyword", "");
            return "board/list";
        }
        String searchKeyword = keyword.trim();
        try {
            long searchCnt = boardSearchService.searchCount(searchKeyword);
            int count = 6;
            PageBean pageBean = new PageBean(page, (int) searchCnt, count);
            List<BoardVO> boards = boardSearchService.search(searchKeyword, page);
            model.addAttribute("boards", boards);
            model.addAttribute("keyword", keyword);
            model.addAttribute("pageBean", pageBean);
        } catch (Exception e) {
            model.addAttribute("searchError", "검색 중 오류가 발생했습니다.");
            e.printStackTrace();
        }
        return "board/list";
    }
}
