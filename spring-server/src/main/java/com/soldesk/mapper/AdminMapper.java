package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.InquiryVO;

public interface AdminMapper {
        List<InquiryVO> selectByCategoryAndStatus(@Param("category") String category, @Param("status") String status);

        List<InquiryVO> selectByCategory(@Param("category") String category);

        int countByCategoryAndStatus(@Param("category") String category, @Param("status") String status);

        // 오류신고 세부코드(ACTION_RECOGNITION 등) 여러개를 한번에 조회 (ERROR_REPORT 통합 필터용)
        List<InquiryVO> selectByCategoryListAndStatus(@Param("categories") List<String> categories,
                        @Param("status") String status);

        List<InquiryVO> selectByCategoryList(@Param("categories") List<String> categories);

        int countByCategoryListAndStatus(@Param("categories") List<String> categories, @Param("status") String status);

        int updateAnswer(@Param("inquiryId") Long inquiryId,
                        @Param("answerContent") String answerContent,
                        @Param("answeredMemberId") Long answeredMemberId);

        // 오류 신고 접수 (사용자 -> inquiry INSERT)
        int insertInquiry(@Param("memberId") Long memberId,
                        @Param("category") String category,
                        @Param("title") String title,
                        @Param("content") String content,
                        @Param("boardId") Integer boardId);

        // 답변할 때 어느 게시글에 댓글 달아야 하는지 찾는 용도
        Integer findBoardIdByInquiry(@Param("inquiryId") Long inquiryId);

        // 사용자가 게시글 내용 수정하면 inquiry 쪽도 맞춰서 갱신
        void updateInquiryContentByBoardId(@Param("boardId") int boardId,
                        @Param("category") String category,
                        @Param("title") String title,
                        @Param("content") String content);

        // 오류 신고 미처리 개수
        int getErrorCount();

        // 오류 유형 카테고리 값 가져오기
        String selectInquiryCategoryByBoardId(@Param("boardId") int boardId);

        int findUserIdByInquiry(Long inquiryId);

}