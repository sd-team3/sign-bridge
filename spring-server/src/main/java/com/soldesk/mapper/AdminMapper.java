package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.InquiryVO;

public interface AdminMapper {
    List<InquiryVO> selectByCategoryAndStatus(@Param("category") String category, @Param("status") String status);

    List<InquiryVO> selectByCategory(@Param("category") String category);

    int countByCategoryAndStatus(@Param("category") String category, @Param("status") String status);

    int updateAnswer(@Param("inquiryId") Long inquiryId,
            @Param("answerContent") String answerContent,
            @Param("answeredMemberId") Long answeredMemberId);

    // 오류 신고 접수 (사용자 -> inquiry INSERT)
    int insertInquiry(@Param("memberId") Long memberId,
            @Param("category") String category,
            @Param("title") String title,
            @Param("content") String content);
}
