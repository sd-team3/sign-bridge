package com.soldesk.controller;

import java.util.List;
import java.util.Map;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.soldesk.service.BoardService;
import com.soldesk.service.MemberService;
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

    @GetMapping("/list")
    public String listBoard(@RequestParam(required = false) String category, @RequestParam(defaultValue = "1") int page, Model model) {
        int boardCnt = boardService.getCategoryBoardCount(category);
        int count = 6;
        PageBean pageBean = new PageBean(page, boardCnt, count);
        List<BoardVO> list = boardService.getBoardByCategory(category, page, count);

        model.addAttribute("boards", list);
        if(category != null) model.addAttribute("category", category);
        model.addAttribute("pageBean", pageBean);

        // 게시글 현황 출력용
        Map<String, Object> boardState = boardService.getBoardState();
        if(boardState != null) model.addAllAttributes(boardState);

        return "board/list";
    }

    @GetMapping("/write")
    public String writeBoard() {
        return "board/write";
    }
    @PostMapping("/write")
    public String writeSubmit(@ModelAttribute BoardVO board) {
        String memberEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        MemberVO member = memberService.getMemberByEmail(memberEmail);

        board.setMemberId(member.getMemberId());
        boardService.writeBoard(board);

        String redirectUrl = "redirect:/board/list";
        return board.getCategoryIdx() != null ? redirectUrl + "?category=" + board.getCategoryIdx() : redirectUrl;
    }

    @GetMapping("/info")
    public String infoBoard(@RequestParam int boardId, Model model, HttpServletRequest request, HttpServletResponse response) {
        Map<String, Object> boardState = boardService.getBoardState();
        if(boardState != null) model.addAllAttributes(boardState);

        String cookieName = "viewed_" + boardId;
        boolean alreadyViewed = false;

        Cookie[] cookies = request.getCookies();
        if(cookies != null) {
            for(Cookie c: cookies) {
                if(c.getName().equals(cookieName)) {
                    alreadyViewed = true;
                    break;
                }
            }
        }

        if (!alreadyViewed) {
            boardService.increaseViewCount(boardId);

            Cookie newCookie = new Cookie(cookieName, "true");
            newCookie.setMaxAge(60*60*24); // 쿠키 만료 시간: 24시간
            newCookie.setPath("/");
            response.addCookie(newCookie);
        }

        BoardVO board = boardService.getBoardByBoardId(boardId);
        model.addAttribute("board", board);

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
        boardService.updateBoard(board);
        return "redirect:/board/info?boardId=" + board.getBoardId();
    }

    @PostMapping("/delete")
    public String deleteBoard(@RequestParam int boardId) {
        boardService.deleteBoard(boardId);
        return "redirect:/board/list";
    }
}
