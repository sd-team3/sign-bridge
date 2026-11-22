package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.InquiryVO;

public interface AdminMapper {
        List<InquiryVO> selectByCategoryAndStatus(@Param("category") String category, @Param("status") String status);

        List<InquiryVO> selectByCategory(@Param("category") String category);

        int countByCategoryAndStatus(@Param("category") String category, @Param("status") String status);


        List<InquiryVO> selectByCategoryListAndStatus(@Param("categories") List<String> categories,
                        @Param("status") String status);

        List<InquiryVO> selectByCategoryList(@Param("categories") List<String> categories);

        int countByCategoryListAndStatus(@Param("categories") List<String> categories, @Param("status") String status);

        int updateAnswer(@Param("inquiryId") Long inquiryId,
                        @Param("answerContent") String answerContent,
                        @Param("answeredMemberId") Long answeredMemberId);


        int insertInquiry(@Param("memberId") Long memberId,
                        @Param("category") String category,
                        @Param("title") String title,
                        @Param("content") String content,
                        @Param("boardId") Integer boardId);


        Integer findBoardIdByInquiry(@Param("inquiryId") Long inquiryId);


        void updateInquiryContentByBoardId(@Param("boardId") int boardId,
                        @Param("category") String category,
                        @Param("title") String title,
                        @Param("content") String content);


        int getErrorCount();


        String selectInquiryCategoryByBoardId(@Param("boardId") int boardId);

        int findUserIdByInquiry(Long inquiryId);

}