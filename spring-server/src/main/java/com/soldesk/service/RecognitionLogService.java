package com.soldesk.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.soldesk.mapper.RecognitionConfirmLogMapper;
import com.soldesk.vo.LandmarkDto;
import com.soldesk.vo.RecognitionConfirmLogVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 자모 하나가 확정될 때마다 recognition_confirm_log에 한 행씩 기록한다.
 *
 * memberId는 서버가 SecurityContext 등을 다시 조회하지 않고, 브라우저가 이미
 * /notification/me 호출로 받아둔 값을 프레임 요청(FrameRequest.memberId)에
 * 그대로 실어보낸 것을 신뢰해서 사용한다. (다른 패키지 추가 의존 없이 그대로 저장만 함)
 */
@Service
public class RecognitionLogService {

    @Autowired
    private RecognitionConfirmLogMapper recognitionConfirmLogMapper;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public void logConfirm(String clientSessionId, Long memberId, String confirmedChar,
                            double confidence, long holdDurationMs, List<LandmarkDto> landmarks) {
        RecognitionConfirmLogVO vo = new RecognitionConfirmLogVO();
        vo.setClientSessionId(clientSessionId);
        vo.setMemberId(memberId);
        vo.setConfirmedChar(confirmedChar);
        vo.setConfidence(confidence);
        vo.setHoldDurationMs((int) holdDurationMs);
        vo.setLandmarkJson(toJson(landmarks));
        recognitionConfirmLogMapper.insertConfirmLog(vo);
    }

    private String toJson(List<LandmarkDto> landmarks) {
        if (landmarks == null || landmarks.isEmpty()) return null;
        try {
            return objectMapper.writeValueAsString(landmarks);
        } catch (Exception e) {
            // 직렬화 실패해도 로그 자체(자모/확신도 등)는 남기는 게 나으므로 landmark_json만 null로 남김
            return null;
        }
    }
}
