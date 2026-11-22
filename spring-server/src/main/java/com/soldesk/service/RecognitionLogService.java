package com.soldesk.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.soldesk.mapper.RecognitionConfirmLogMapper;
import com.soldesk.vo.LandmarkDto;
import com.soldesk.vo.RecognitionConfirmLogVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;








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

            return null;
        }
    }
}
