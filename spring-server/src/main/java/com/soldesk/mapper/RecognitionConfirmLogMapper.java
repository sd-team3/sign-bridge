package com.soldesk.mapper;

import com.soldesk.vo.RecognitionConfirmLogVO;

import java.time.LocalDateTime;
import java.util.List;

public interface RecognitionConfirmLogMapper {

    /** 자모 하나 확정될 때마다 한 행 삽입. */
    int insertConfirmLog(RecognitionConfirmLogVO vo);

    /** (선택) 특정 세션의 확정 로그 전체 조회 - 학습 기록 화면 등에서 재사용 가능. */
    List<RecognitionConfirmLogVO> findByClientSessionId(String clientSessionId);

    /** (선택) 로그인 회원 기준 확정 로그 전체 조회. */
    List<RecognitionConfirmLogVO> findByMemberId(Long memberId);

    /** 학습 메인페이지 "최근 학습" 표시용 - 가장 최근 확정 로그 시각 1건만 조회. 기록 없으면 null. */
    LocalDateTime findLastRegDateByMemberId(Long memberId);
}
