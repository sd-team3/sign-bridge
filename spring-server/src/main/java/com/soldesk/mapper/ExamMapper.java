package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.TestSessionDetailVO;
import com.soldesk.vo.TestSessionVO;
import com.soldesk.vo.WrongAnswerVO;

public interface ExamMapper {

    void insertSession(TestSessionVO session);

    void updateSessionResult(@Param("testSessionId") Long testSessionId,
                              @Param("correctCount") int correctCount,
                              @Param("score") int score);

    TestSessionVO selectSession(@Param("testSessionId") Long testSessionId);

    void insertAnswer(TestSessionDetailVO detail);

    List<WrongAnswerVO> selectWrongAnswers(@Param("testSessionId") Long testSessionId);
}