package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.LearnMapper;
import com.soldesk.vo.JamoVO;

@Service
public class LearnService {
    
    @Autowired
    private LearnMapper learnMapper;

    public List<JamoVO> getConsonants(){
        return learnMapper.findByType("CONSONANT");
    }

    public List<JamoVO> getVowels(){
        return learnMapper.findByType("VOWEL");
    }
}
