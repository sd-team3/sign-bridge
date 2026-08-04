package com.soldesk.mapper;

import com.soldesk.vo.RecognitionConfirmLogVO;

import java.util.List;

public interface RecognitionConfirmLogMapper {

    /** 자모 하나 확정될 때마다 한 행 삽입. */
    int insertConfirmLog(RecognitionConfirmLogVO vo);

    /** (선택) 특정 세션의 확정 로그 전체 조회 - 학습 기록 화면 등에서 재사용 가능. */
    List<RecognitionConfirmLogVO> findByClientSessionId(String clientSessionId);

    /** (선택) 로그인 회원 기준 확정 로그 전체 조회. */
    List<RecognitionConfirmLogVO> findByMemberId(Long memberId);
}
