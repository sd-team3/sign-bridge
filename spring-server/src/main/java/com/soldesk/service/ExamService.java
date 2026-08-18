package com.soldesk.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.SignWordMapper;
import com.soldesk.mapper.ExamMapper;
import com.soldesk.vo.ExamQuestionVO;
import com.soldesk.vo.ExamResultVO;
import com.soldesk.vo.SignWordVO;
import com.soldesk.vo.TestSessionDetailVO;
import com.soldesk.vo.TestSessionVO;

@Service
public class ExamService {

    @Autowired
    private SignWordMapper signWordMapper;

    @Autowired
    private ExamMapper examMapper;

    private List<ExamQuestionVO> buildQuizQuestions(List<SignWordVO> words) {
        int objectiveCount = (int) Math.ceil(words.size() / 2.0);
        List<ExamQuestionVO> result = new ArrayList<>();

        for (int i = 0; i < words.size(); i++) {
            SignWordVO w = words.get(i);
            boolean isSubjective = i >= objectiveCount;

            ExamQuestionVO q = new ExamQuestionVO();
            q.setSignWordId(w.getSignWordId());
            q.setWord(w.getSignWordName());
            q.setType(isSubjective ? "subjective" : "choice");

            if (!isSubjective) {
                List<SignWordVO> distractors = signWordMapper.findRandomChoices(w.getSignWordId(), 3);
                List<String> choices = new ArrayList<>();
                for (SignWordVO d : distractors) {
                    choices.add(d.getSignWordName());
                }
                choices.add(w.getSignWordName());
                Collections.shuffle(choices);
                q.setChoices(choices);
            }
            result.add(q);
        }
        return result;
    }

    private List<ExamQuestionVO> buildMotionQuestions(List<SignWordVO> words) {
        List<ExamQuestionVO> result = new ArrayList<>();
        for (SignWordVO w : words) {
            ExamQuestionVO q = new ExamQuestionVO();
            q.setSignWordId(w.getSignWordId());
            q.setWord(w.getSignWordName());
            q.setType("motion");
            q.setDescription(w.getDescription());
            result.add(q);
        }
        return result;
    }

    public Long startSession(int memberId, String mode, int count, HttpSession httpSession) {
        TestSessionVO session = new TestSessionVO();
        session.setMemberId(memberId);
        session.setTestSessionType(mode);
        session.setNumOfQuestion(count);
        examMapper.insertSession(session);
        Long sessionId = session.getTestSessionId();

        if ("both".equals(mode)) {
            int phaseCount = (int) Math.ceil(count / 2.0);
            List<SignWordVO> words = signWordMapper.findRandomList(phaseCount * 2);
            List<SignWordVO> choiceWords = words.subList(0, phaseCount);
            List<SignWordVO> motionWords = words.subList(phaseCount, words.size());

            httpSession.setAttribute("exam_" + sessionId + "_choice", buildQuizQuestions(choiceWords));
            httpSession.setAttribute("exam_" + sessionId + "_motion", buildMotionQuestions(motionWords));

        } else if ("motion".equals(mode)) {
            List<SignWordVO> words = signWordMapper.findRandomList(count);
            httpSession.setAttribute("exam_" + sessionId + "_motion", buildMotionQuestions(words));

        } else { // choice
            List<SignWordVO> words = signWordMapper.findRandomList(count);
            httpSession.setAttribute("exam_" + sessionId + "_choice", buildQuizQuestions(words));
        }

        return sessionId;
    }

    @SuppressWarnings("unchecked")
    public List<ExamQuestionVO> getPhaseQuestions(Long sessionId, String phase, HttpSession httpSession) {
        Object stored = httpSession.getAttribute("exam_" + sessionId + "_" + phase);
        if (stored == null) return new ArrayList<>();
        return (List<ExamQuestionVO>) stored;
    }

    /** 문제 하나 답안 저장 */
    public void submitAnswer(Long testSessionId, Long signWordId, int questionNo, String userAnswer, boolean isCorrect) {
        TestSessionDetailVO detail = new TestSessionDetailVO();
        detail.setTestSessionId(testSessionId);
        detail.setSignWordId(signWordId);
        detail.setQuestionNo(questionNo);
        detail.setUserAnswer(userAnswer);
        detail.setIsCorrect(isCorrect ? "Y" : "N");
        examMapper.insertAnswer(detail);
    }

    /** 시험 종료: 점수 계산해서 세션 업데이트 */
    public void finishSession(Long testSessionId, int correctCount, int totalCount) {
        int score = (int) Math.round((correctCount * 100.0) / totalCount);
        examMapper.updateSessionResult(testSessionId, correctCount, score);
    }

    public ExamResultVO getResult(Long testSessionId) {
        ExamResultVO result = new ExamResultVO();
        result.setSession(examMapper.selectSession(testSessionId));
        result.setWrongList(examMapper.selectWrongAnswers(testSessionId));
        return result;
    }
}