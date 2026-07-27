package com.soldesk.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.ExamMapper;

@Service
public class ExamService {
    
    @Autowired
    private ExamMapper examMapper;
}
