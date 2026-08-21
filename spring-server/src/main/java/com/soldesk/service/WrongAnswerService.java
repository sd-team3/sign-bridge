package com.soldesk.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.WrongAnswerMapper;
import com.soldesk.vo.WrongAnswerVO;

@Service
public class WrongAnswerService {

    @Autowired
    private WrongAnswerMapper wrongAnswerMapper;

    private static final int PAGE_SIZE = 10;

    public Map<String, Object> getWrongAnswersByMember(int memberId, String category, int page) {
        int total = wrongAnswerMapper.countWrongAnswersByMemberId(memberId, category);
        int offset = (page - 1) * PAGE_SIZE;

        List<WrongAnswerVO> list = wrongAnswerMapper.findWrongAnswersByMemberId(memberId, category, offset, PAGE_SIZE);

        int totalPages = (int) Math.ceil((double) total / PAGE_SIZE);

        Map<String, Object> result = new HashMap<>();
        result.put("wrongAnswers", list);
        result.put("currentPage", page);
        result.put("totalPages", totalPages);
        result.put("totalCount", total);
        return result;
    }
}