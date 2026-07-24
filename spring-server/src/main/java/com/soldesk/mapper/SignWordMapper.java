package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.SignWordVO;

public interface SignWordMapper {

    List<SignWordVO> findList(@Param("choseong") String choseong, @Param("keyword") String keyword);

    SignWordVO findByName(@Param("signWordName") String signWordName);

    void incrementViewCount(@Param("signWordName") String signWordName);

    SignWordVO findRandom();
}