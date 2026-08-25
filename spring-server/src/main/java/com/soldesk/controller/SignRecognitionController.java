package com.soldesk.controller;

import com.soldesk.service.RecognitionLogService;
import com.soldesk.vo.FrameRequest;
import com.soldesk.vo.FrameResponse;
import com.soldesk.vo.LandmarkDto;
import com.soldesk.vo.PredictResponse;
import com.soldesk.vo.RecognitionState;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import javax.servlet.http.HttpSession;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/sign")
public class SignRecognitionController {

    @Value("${python.server.url}")
    private String pythonServerUrl;

    @Autowired
    private RecognitionLogService recognitionLogService;

    private final RestTemplate restTemplate = new RestTemplate();

    private static final long HOLD_THRESHOLD_MS = 1200;     // 1.2초 유지하면 확정
    private static final double CONFIDENCE_THRESHOLD = 0.6;  // 이보다 확신도 낮으면 유지 판정 자체를 안 함
    private static final String SESSION_KEY = "signRecognitionState";

    @PostMapping("/frame")
    public FrameResponse processFrame(@RequestBody FrameRequest req, HttpSession session) {
        RecognitionState state = getOrCreateState(session);

        PredictResponse predicted = callPredict(req.getLandmarks(), req.isMirror());

        long now = System.currentTimeMillis();
        String rawLabel = predicted != null ? predicted.getLabel() : null;
        double rawConfidence = predicted != null ? predicted.getConfidence() : 0.0;

        // 브라우저(로컬스토리지)가 만들어 보내는 값을 우선 쓰고, 없으면 서버 세션 id로 대체
        String clientSessionId = (req.getClientSessionId() != null && !req.getClientSessionId().isBlank())
            ? req.getClientSessionId()
            : session.getId();
        if (clientSessionId.length() > 50) {
            clientSessionId = clientSessionId.substring(0, 50); // 컬럼이 VARCHAR(50)
        }

        FrameResponse res = new FrameResponse();
        res.setRawLabel(rawLabel);
        res.setRawConfidence(rawConfidence);

        boolean acceptable = rawLabel != null && rawConfidence >= CONFIDENCE_THRESHOLD;

        if (!acceptable) {
            // 확신도가 낮으면 유지 판정을 초기화한다 (흔들리는 손 모양이 잘못 확정되지 않도록)
            state.setCandidate(null, now);
            res.setHoldProgress(0);
        } else if (!state.isSameCandidate(rawLabel)) {
            // 라벨이 바뀜 -> 새로 유지 시작
            state.setCandidate(rawLabel, now);
            res.setHoldProgress(0);
        } else {
            // 같은 라벨을 계속 유지 중
            long held = state.getHoldMillis(now);
            double progress = Math.min(1.0, held / (double) HOLD_THRESHOLD_MS);
            res.setHoldProgress(progress);

            if (held >= HOLD_THRESHOLD_MS && !state.isCandidateConfirmed()) {
                state.getComposer().addJamo(rawLabel.charAt(0), now);
                state.markConfirmed();
                res.setConfirmedChar(rawLabel);

                recognitionLogService.logConfirm(
                    clientSessionId, req.getMemberId(), rawLabel, rawConfidence, held, req.getLandmarks()
                );
            }
        }

        res.setComposedText(state.getComposer().getText());
        return res;
    }

    @PostMapping("/space")
    public FrameResponse insertSpace(HttpSession session) {
        RecognitionState state = getOrCreateState(session);
        state.getComposer().appendSpace();
        FrameResponse res = new FrameResponse();
        res.setComposedText(state.getComposer().getText());
        return res;
    }

    @PostMapping("/reset")
    public FrameResponse reset(HttpSession session) {
        session.removeAttribute(SESSION_KEY);
        RecognitionState state = getOrCreateState(session);
        FrameResponse res = new FrameResponse();
        res.setComposedText(state.getComposer().getText());
        return res;
    }

    private RecognitionState getOrCreateState(HttpSession session) {
        RecognitionState state = (RecognitionState) session.getAttribute(SESSION_KEY);
        if (state == null) {
            state = new RecognitionState();
            session.setAttribute(SESSION_KEY, state);
        }
        return state;
    }

    private PredictResponse callPredict(List<LandmarkDto> landmarks, boolean mirror) {
        if (landmarks == null || landmarks.isEmpty()) return null;

        Map<String, Object> body = new HashMap<>();
        body.put("landmarks", landmarks);
        body.put("mirror", mirror);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<PredictResponse> response = restTemplate.postForEntity(
                pythonServerUrl + "/predict", request, PredictResponse.class
            );
            return response.getBody();
        } catch (Exception e) {
            return null;
        }
    }
}