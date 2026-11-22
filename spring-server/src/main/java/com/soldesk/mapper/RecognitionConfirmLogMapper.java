package com.soldesk.mapper;

import com.soldesk.vo.RecognitionConfirmLogVO;

import java.time.LocalDateTime;
import java.util.List;

public interface RecognitionConfirmLogMapper {


    int insertConfirmLog(RecognitionConfirmLogVO vo);


    List<RecognitionConfirmLogVO> findByClientSessionId(String clientSessionId);


    List<RecognitionConfirmLogVO> findByMemberId(Long memberId);


    LocalDateTime findLastRegDateByMemberId(Long memberId);
}
