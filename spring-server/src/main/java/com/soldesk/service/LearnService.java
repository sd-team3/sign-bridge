package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.LearnMapper;
import com.soldesk.mapper.SignWordMapper;
import com.soldesk.vo.JamoVO;
import com.soldesk.vo.SignWordVO;

@Service
public class LearnService {

    @Autowired
    private LearnMapper learnMapper;

    @Autowired
    private SignWordMapper signWordMapper;

    public List<JamoVO> getConsonants() {
        return learnMapper.findByType("CONSONANT");
    }

    public List<JamoVO> getVowels() {
        return learnMapper.findByType("VOWEL");
    }

    public List<SignWordVO> getDictWords(String choseong, String keyword) {
        return signWordMapper.findList(choseong, keyword);
    }

    public SignWordVO getDictWordDetail(String signWordName) {
        return signWordMapper.findByName(signWordName);
    }

    public void increaseViewCount(String signWordName) {
        signWordMapper.incrementViewCount(signWordName);
    }

    public SignWordVO getRandomDictWord() {
        return signWordMapper.findRandom();
    }
}