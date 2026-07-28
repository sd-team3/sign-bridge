package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.mapper.BoardMapper;
import com.soldesk.vo.BoardVO;

@Service
public class BoardService {
    
    @Autowired
    private BoardMapper boardMapper;

    @Transactional
    public List<BoardVO> getBoardByCategory(String category, int page, int count) {
        int start = (page - 1) * count;
        List<BoardVO> list = boardMapper.findByCategory(category, start, count);
        return list;
    }
    @Transactional
    public int getCategoryBoardCount(String category) {
        return boardMapper.countByCategoryBoard(category);
    }
}
