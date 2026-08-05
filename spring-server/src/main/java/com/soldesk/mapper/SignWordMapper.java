package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.SignWordVO;

public interface SignWordMapper {

    List<SignWordVO> findList(@Param("choseong") String choseong, @Param("keyword") String keyword);

    SignWordVO findByName(@Param("signWordName") String signWordName);

    void incrementViewCount(@Param("signWordName") String signWordName);

    SignWordVO findRandom();
    // 어드민 간단한 단어 리스트 (페이징)
    List<SignWordVO> getWordList(@Param("keyword") String keyword,
                          @Param("offset") int offset,
                          @Param("pageSize") int pageSize);

    // 어드민 단어 개수
    int getCount(String keyword);

    // 단어 아이디로 단어 이름 구하기
    SignWordVO getDictWordDetailById(int signWordId);

    // 단어 수정
    void updateWord(@Param("signWordId") int signWordId,
                    @Param("signWordName") String signWordName,
                    @Param("choseong") String choseong,
                    @Param("signWordVideo") String signWordVideo,
                    @Param("signWordThumbnail") String signWordThumbnail,
                    @Param("description") String description
    );

    // 시험 문제 랜덤 출제
    List<SignWordVO> findRandomList(@Param("count") int count);

    // 시험 객관식 오답 보기
    List<SignWordVO> findRandomChoices(@Param("excludeId") long excludeId, @Param("limit") int limit);
}