package com.soldesk.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
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
    public String listBoard(@RequestParam String category, @RequestParam(defaultValue = "1") int page, Model model) {
        int boardCnt = boardService.getCategoryBoardCount(category);
        int count = 6;
        PageBean pageBean = new PageBean(page, boardCnt, count);
        List<BoardVO> list = boardService.getBoardByCategory(category, page, count);

        model.addAttribute("boards", list);
        if(category != null) model.addAttribute("category", category);
        model.addAttribute("pageBean", pageBean);

        return "board/list";
    }

    @GetMapping("/write")
    public String writeBoard() {
        return "board/write";
    }
    // @PostMapping("/write")
    // public String writeSubmit() {
    //     String memberEmail = SecurityContextHolder.getContext().getAuthentication().getName();
    //     MemberVO member = memberService.getMemberByEmail(memberEmail);
    // }
}
