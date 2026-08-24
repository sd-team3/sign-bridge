package com.soldesk.mapper;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.ChainWordVO;

public interface ChainWordMapper {

    /** 끝말잇기 검증 단어집(chain_word)에서 단어명으로 조회. 있으면 이미 검증된 단어. */
    ChainWordVO findByName(@Param("wordName") String wordName);

    java.util.List<ChainWordVO> findAll();

    /** 국립국어원 API로 새로 검증된 단어를 캐시에 적재 (동시 검증 충돌 시 무시) */
    void insertIgnore(ChainWordVO chainWord);
}
