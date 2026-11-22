package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.SignWordVO;

public interface SignWordMapper {

    List<SignWordVO> findList(@Param("choseong") String choseong, @Param("keyword") String keyword);

    SignWordVO findByName(@Param("signWordName") String signWordName);

    void incrementViewCount(@Param("signWordName") String signWordName);

    SignWordVO findRandom();

    List<SignWordVO> getWordList(@Param("keyword") String keyword,
                          @Param("offset") int offset,
                          @Param("pageSize") int pageSize);


    int getCount(String keyword);


    SignWordVO getDictWordDetailById(int signWordId);


    void updateWord(@Param("signWordId") int signWordId,
                    @Param("signWordName") String signWordName,
                    @Param("choseong") String choseong,
                    @Param("signWordVideo") String signWordVideo,
                    @Param("signWordThumbnail") String signWordThumbnail,
                    @Param("description") String description
    );


    List<SignWordVO> findRandomList(@Param("count") int count);


    List<SignWordVO> findRandomChoices(@Param("excludeId") long excludeId, @Param("limit") int limit);
}