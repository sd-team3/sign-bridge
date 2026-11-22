package com.soldesk.mapper;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.ChainWordVO;

public interface ChainWordMapper {


    ChainWordVO findByName(@Param("wordName") String wordName);

    java.util.List<ChainWordVO> findAll();


    void insertIgnore(ChainWordVO chainWord);
}
