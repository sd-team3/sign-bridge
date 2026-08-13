package com.soldesk.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.LearningHistoryMapper;
import com.soldesk.vo.JamoHistoryVO;
import com.soldesk.vo.WordHistoryVO;

@Service
public class LearningHistoryService {
    @Autowired
    private LearningHistoryMapper learningHistoryMapper;

    private static final int PAGE_SIZE = 10;

    public Map<String, Object> getJamoHistoryByMember(int memberId, String category, int page) {
        int total = learningHistoryMapper.countJamoHistoryByMemberId(memberId, category);
        int offset = (page - 1) * PAGE_SIZE;
        List<JamoHistoryVO> list = learningHistoryMapper.findJamoHistoryByMemberId(memberId, category, offset, PAGE_SIZE);
        int totalPages = (int) Math.ceil((double) total / PAGE_SIZE);

        Map<String, Object> result = new HashMap<>();
        result.put("jamoHistory", list);
        result.put("currentPage", page);
        result.put("totalPages", totalPages);
        result.put("totalCount", total);
        return result;
    }

    public Map<String, Object> getWordHistoryByMember(int memberId, String category, int page) {
        int total = learningHistoryMapper.countWordHistoryByMemberId(memberId, category);
        int offset = (page - 1) * PAGE_SIZE;
        List<WordHistoryVO> list = learningHistoryMapper.findWordHistoryByMemberId(memberId, category, offset, PAGE_SIZE);
        int totalPages = (int) Math.ceil((double) total / PAGE_SIZE);

        Map<String, Object> result = new HashMap<>();
        result.put("wordHistory", list);
        result.put("currentPage", page);
        result.put("totalPages", totalPages);
        result.put("totalCount", total);
        return result;
    }
}
