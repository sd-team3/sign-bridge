package com.soldesk.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.BoardErrorReportMapper;

@Service
public class BoardErrorReportService {
    @Autowired
    private BoardErrorReportMapper boardErrorReportMapper;
    
    public void insertError(int boardId, String errorType, String relatedWord) {
        boardErrorReportMapper.insert(boardId, errorType, relatedWord);
    }
}
