package com.soldesk.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.ui.Model;

@Controller
@RequestMapping("/playzone/chain")
public class ChainController {

    @GetMapping("")
    public String lobby() {
        return "playzone/chain/lobby";
    }

    @GetMapping("/{roomId}")
    public String room(@PathVariable long roomId, Model model) {
        model.addAttribute("roomId", roomId);
        return "playzone/chain/room";
    }
}
