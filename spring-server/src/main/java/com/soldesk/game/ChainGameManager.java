package com.soldesk.game;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.soldesk.dto.ChainFrameResponse;
import com.soldesk.dto.ChainWordValidationResult;
import com.soldesk.mapper.ChainRoomMapper;
import com.soldesk.mapper.ChainWordLogMapper;
import com.soldesk.mapper.MemberMapper;
import com.soldesk.service.ChainWordValidationService;
import com.soldesk.vo.ChainWordLogVO;
import com.soldesk.vo.LandmarkDto;
import com.soldesk.vo.PredictResponse;
import com.soldesk.vo.RecognitionState;

@Service
public class ChainGameManager implements DisposableBean {

    private static final Logger log = LoggerFactory.getLogger(ChainGameManager.class);

    private static final long HOLD_THRESHOLD_MS = 1200;
    private static final double CONFIDENCE_THRESHOLD = 0.6;
    private static final long EXTEND_PER_JAMO_MS = 2000; // 요구사항 7: 자모 하나 확정마다 +2초
    private static final int WINNER_BONUS_SCORE = 100;   // 요구사항 6: 최후 1인 우승 보너스 점수

    @Value("${python.server.url}")
    private String pythonServerUrl;

    @Autowired private ChainRoomMapper chainRoomMapper;
    @Autowired private ChainWordLogMapper chainWordLogMapper;
    @Autowired private MemberMapper memberMapper;
    @Autowired private ChainWordValidationService validationService;

    private final Map<Long, ChainRoomState> rooms = new ConcurrentHashMap<>();
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(4, r -> {
        Thread t = new Thread(r, "chain-game-scheduler");
        t.setDaemon(true);
        return t;
    });

    private final ExecutorService persistenceExecutor = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "chain-persistence");
        t.setDaemon(true);
        return t;
    });

    @Override
    public void destroy() {
        scheduler.shutdownNow();
        persistenceExecutor.shutdown();
    }

    public ChainRoomState getState(long roomId) {
        return rooms.get(roomId);
    }

    public void registerSession(long roomId, WebSocketSession session) {
        ChainRoomState state = rooms.get(roomId);
        if (state != null) state.getSessions().add(session);
    }

    public void unregisterSession(long roomId, WebSocketSession session) {
        ChainRoomState state = rooms.get(roomId);
        if (state != null) state.getSessions().remove(session);
    }

    private final Map<Long, java.util.Set<WebSocketSession>> lobbySessions = new ConcurrentHashMap<>();

    public void registerLobbySession(long roomId, WebSocketSession session) {
        lobbySessions.computeIfAbsent(roomId, k -> ConcurrentHashMap.newKeySet()).add(session);
    }

    public void unregisterLobbySession(long roomId, WebSocketSession session) {
        java.util.Set<WebSocketSession> set = lobbySessions.get(roomId);
        if (set != null) set.remove(session);
    }

    public void broadcastLobby(long roomId, String type, Object payload) {
        java.util.Set<WebSocketSession> set = lobbySessions.get(roomId);
        if (set == null || set.isEmpty()) return;
        String json = toJson(type, payload);
        for (WebSocketSession s : set) sendSafe(s, json);
    }

    public void broadcast(long roomId, String type, Object payload) {
        ChainRoomState state = rooms.get(roomId);
        String json = toJson(type, payload);
        if (state != null) {
            for (WebSocketSession s : state.getSessions()) sendSafe(s, json);
        }
        java.util.Set<WebSocketSession> lobby = lobbySessions.get(roomId);
        if (lobby != null) {
            for (WebSocketSession s : lobby) sendSafe(s, json);
        }
    }

    private String toJson(String type, Object payload) {
        try {
            Map<String, Object> envelope = new HashMap<>();
            envelope.put("type", type);
            envelope.put("payload", payload);
            return objectMapper.writeValueAsString(envelope);
        } catch (Exception e) {
            log.error("WS 메시지 직렬화 실패", e);
            return "{\"type\":\"ERROR\"}";
        }
    }

    private void sendSafe(WebSocketSession session, String json) {
        try {
            if (session.isOpen()) session.sendMessage(new TextMessage(json));
        } catch (IOException e) {
            log.warn("WS 전송 실패 (세션 {}): {}", session.getId(), e.getMessage());
        }
    }

    public void startGame(long roomId, List<Integer> orderedMemberIds, int baseSec) {
        ChainRoomState state = new ChainRoomState(roomId, baseSec);
        state.setTurnOrder(orderedMemberIds);
        state.setCurrentTurnIndex(0);
        state.setRequiredFirstChar(null);
        state.initLivesAndScore(orderedMemberIds);
        long deadline = System.currentTimeMillis() + baseSec * 1000L;
        state.setTurnDeadlineEpochMillis(deadline);
        rooms.put(roomId, state);

        java.util.Set<WebSocketSession> lobby = lobbySessions.remove(roomId);
        if (lobby != null) state.getSessions().addAll(lobby);

        scheduleTimeout(state);

        Map<String, Object> payload = new HashMap<>();
        payload.put("currentTurnMemberId", state.getCurrentTurnMemberId());
        payload.put("deadlineEpochMillis", deadline);
        payload.put("requiredFirstChar", null);
        payload.put("turnOrder", orderedMemberIds);
        broadcast(roomId, "GAME_START", payload);
    }

    private void scheduleTimeout(ChainRoomState state) {
        long delay = Math.max(0, state.getTurnDeadlineEpochMillis() - System.currentTimeMillis());
        state.setTimeoutTask(scheduler.schedule(() -> onTimeoutFired(state.getRoomId()), delay, TimeUnit.MILLISECONDS));
    }

    private void onTimeoutFired(long roomId) {
        ChainRoomState state = rooms.get(roomId);
        if (state == null || state.isEnded()) return;
        Integer memberId = state.getCurrentTurnMemberId();
        if (memberId == null) return;
        if (System.currentTimeMillis() < state.getTurnDeadlineEpochMillis()) return;
        resolveTurn(state, memberId, null, true);
    }

    public ChainFrameResponse processFrame(long roomId, int memberId, List<LandmarkDto> landmarks, boolean mirror) {
        ChainRoomState state = rooms.get(roomId);
        ChainFrameResponse res = new ChainFrameResponse();
        if (state == null || state.isEnded()) return res;

        Integer currentTurnMemberId = state.getCurrentTurnMemberId();
        if (currentTurnMemberId == null || currentTurnMemberId != memberId) {
            res.setComposedText("");
            return res;
        }

        RecognitionState composerState = state.getCurrentComposerState();
        PredictResponse predicted = callPredict(landmarks, mirror);

        long now = System.currentTimeMillis();
        String rawLabel = predicted != null ? predicted.getLabel() : null;
        double rawConfidence = predicted != null ? predicted.getConfidence() : 0.0;

        res.setRawLabel(rawLabel);
        res.setRawConfidence(rawConfidence);

        boolean acceptable = rawLabel != null && rawConfidence >= CONFIDENCE_THRESHOLD;

        if (!acceptable) {
            composerState.setCandidate(null, now);
            res.setHoldProgress(0);
        } else if (!composerState.isSameCandidate(rawLabel)) {
            composerState.setCandidate(rawLabel, now);
            res.setHoldProgress(0);
        } else {
            long held = composerState.getHoldMillis(now);
            double progress = Math.min(1.0, held / (double) HOLD_THRESHOLD_MS);
            res.setHoldProgress(progress);

            if (held >= HOLD_THRESHOLD_MS && !composerState.isCandidateConfirmed()) {
                composerState.getComposer().addJamo(rawLabel.charAt(0));
                composerState.markConfirmed();
                res.setConfirmedChar(rawLabel);

                state.extendDeadline(EXTEND_PER_JAMO_MS);
                scheduleTimeout(state);

                Map<String, Object> progressPayload = new HashMap<>();
                progressPayload.put("memberId", memberId);
                progressPayload.put("confirmedChar", rawLabel);
                progressPayload.put("composedText", composerState.getComposer().getText());
                progressPayload.put("deadlineEpochMillis", state.getTurnDeadlineEpochMillis());
                broadcast(roomId, "PROGRESS", progressPayload);
            }
        }

        res.setComposedText(composerState.getComposer().getText());
        res.setRemainingMillis(Math.max(0, state.getTurnDeadlineEpochMillis() - now));
        return res;
    }

    private PredictResponse callPredict(List<LandmarkDto> landmarks, boolean mirror) {
        if (landmarks == null || landmarks.isEmpty()) return null;
        Map<String, Object> body = new HashMap<>();
        body.put("landmarks", landmarks);
        body.put("mirror", mirror);

        org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
        headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);
        org.springframework.http.HttpEntity<Map<String, Object>> request =
            new org.springframework.http.HttpEntity<>(body, headers);
        try {
            org.springframework.http.ResponseEntity<PredictResponse> response = restTemplate.postForEntity(
                pythonServerUrl + "/predict", request, PredictResponse.class
            );
            return response.getBody();
        } catch (Exception e) {
            return null;
        }
    }

    public void submitComplete(long roomId, int memberId) {
        ChainRoomState state = rooms.get(roomId);
        if (state == null || state.isEnded()) return;
        Integer currentTurnMemberId = state.getCurrentTurnMemberId();
        if (currentTurnMemberId == null || currentTurnMemberId != memberId) return;

        RecognitionState composerState = state.getCurrentComposerState();
        composerState.getComposer().commitPending();
        String word = composerState.getComposer().getText().trim();
        resolveTurn(state, memberId, word, false);
    }

    private void resolveTurn(ChainRoomState state, int memberId, String attemptedWord, boolean isTimeout) {
        ReentrantLock lock = state.getTurnLock();
        lock.lock();
        try {
            if (state.isEnded()) return;
            Integer currentTurnMemberId = state.getCurrentTurnMemberId();
            if (currentTurnMemberId == null || currentTurnMemberId != memberId) return;

            long roomId = state.getRoomId();
            String word = attemptedWord == null ? "" : attemptedWord.trim();

            boolean valid;
            String reasonCode = null;
            Long chainWordId = null;

            if (isTimeout) {
                valid = false;
                reasonCode = ChainWordLogVO.REASON_TIMEOUT;
            } else if (word.isEmpty()) {
                valid = false;
                reasonCode = ChainWordLogVO.REASON_NOT_FOUND;
            } else if (state.getUsedWords().contains(word)) {
                valid = false;
                reasonCode = ChainWordLogVO.REASON_DUPLICATE;
            } else {
                ChainWordValidationResult result = validationService.validate(word, state.getRequiredFirstChar());
                valid = result.isValid();
                if (valid) chainWordId = result.getChainWordId();
                else reasonCode = result.getReasonCode();
            }

            int scoreDelta = 0;
            int newLives = state.getLives(memberId);
            boolean justEliminated = false;

            if (valid) {
                state.getUsedWords().add(word);
                state.setRequiredFirstChar(word.substring(word.length() - 1));
                scoreDelta = word.length() * 10;
                state.addScore(memberId, scoreDelta);
            } else {
                newLives = Math.max(0, newLives - 1);
                state.setLives(memberId, newLives);
                if (newLives <= 0 && !state.isEliminated(memberId)) {
                    state.markEliminated(memberId);
                    justEliminated = true;
                }
            }

            final Long finalChainWordId = chainWordId;
            final int finalTurnNo = nextTurnNo(state);
            final String finalReasonCode = reasonCode;
            final boolean finalValid = valid;
            final String finalWord = word;
            final int finalScoreDelta = scoreDelta;
            final int finalNewLives = newLives;
            final boolean finalJustEliminated = justEliminated;

            Map<String, Object> resultPayload = new HashMap<>();
            resultPayload.put("memberId", memberId);
            resultPayload.put("attemptedWord", word);
            resultPayload.put("valid", valid);
            resultPayload.put("reasonCode", reasonCode);
            resultPayload.put("scoreDelta", scoreDelta);
            resultPayload.put("lives", newLives);
            resultPayload.put("eliminated", newLives <= 0);
            resultPayload.put("requiredFirstChar", state.getRequiredFirstChar());
            broadcast(roomId, "WORD_RESULT", resultPayload);

            persistenceExecutor.execute(() -> {
                ChainWordLogVO logVO = new ChainWordLogVO();
                logVO.setChainRoomId(roomId);
                logVO.setMemberId(memberId);
                logVO.setChainWordId(finalChainWordId);
                logVO.setAttemptedWord(finalWord.isEmpty() ? "(미입력)" : finalWord);
                logVO.setTurnNo(finalTurnNo);
                logVO.setIsValid(finalValid ? "Y" : "N");
                logVO.setInvalidReasonCode(finalReasonCode);
                chainWordLogMapper.insertLog(logVO);

                chainRoomMapper.updateLivesAndScore(roomId, memberId, finalNewLives, finalScoreDelta);
                if (finalScoreDelta > 0) memberMapper.addPoint(memberId, finalScoreDelta);
                if (finalJustEliminated) chainRoomMapper.eliminateMember(roomId, memberId, LocalDateTime.now());
            });

            if (state.aliveCount() <= 1) {
                endGame(state);
                return;
            }

            int nextIdx = state.nextAliveIndex(state.getCurrentTurnIndex());
            state.setCurrentTurnIndex(nextIdx);
            state.resetComposerState();
            long deadline = System.currentTimeMillis() + state.getTurnTimeLimitBaseSec() * 1000L;
            state.setTurnDeadlineEpochMillis(deadline);
            scheduleTimeout(state);

            Integer nextTurnMemberId = state.getCurrentTurnMemberId();
            persistenceExecutor.execute(() ->
                chainRoomMapper.advanceTurn(roomId, nextTurnMemberId, toLocalDateTime(deadline), finalChainWordId)
            );

            Map<String, Object> turnPayload = new HashMap<>();
            turnPayload.put("currentTurnMemberId", nextTurnMemberId);
            turnPayload.put("deadlineEpochMillis", deadline);
            turnPayload.put("requiredFirstChar", state.getRequiredFirstChar());
            turnPayload.put("alternativeFirstChar", validationService.alternativeFirstChar(state.getRequiredFirstChar()));
            broadcast(roomId, "TURN_START", turnPayload);

        } finally {
            lock.unlock();
        }
    }

    private final Map<Long, java.util.concurrent.atomic.AtomicInteger> turnCounters = new ConcurrentHashMap<>();

    private int nextTurnNo(ChainRoomState state) {
        return turnCounters.computeIfAbsent(state.getRoomId(), k -> new java.util.concurrent.atomic.AtomicInteger(0))
                .incrementAndGet();
    }

    private void endGame(ChainRoomState state) {
        long roomId = state.getRoomId();
        state.setEnded(true);
        if (state.getTimeoutTask() != null) state.getTimeoutTask().cancel(false);

        List<Integer> alive = new ArrayList<>(state.aliveMembersInOrder());
        Integer winnerId = alive.isEmpty() ? null : alive.get(0);

        if (winnerId != null) {
            state.addScore(winnerId, WINNER_BONUS_SCORE);
        }

        List<Integer> eliminationOrder = new ArrayList<>(state.getEliminationOrder());
        java.util.Collections.reverse(eliminationOrder);

        Map<Integer, Integer> finalRanks = new HashMap<>();
        if (winnerId != null) finalRanks.put(winnerId, 1);
        int rank = 2;
        for (Integer loserId : eliminationOrder) {
            finalRanks.put(loserId, rank++);
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("winnerMemberId", winnerId);
        payload.put("finalRanks", finalRanks);
        Map<Integer, Integer> finalScores = new HashMap<>();
        for (Integer id : state.getTurnOrder()) finalScores.put(id, state.getScore(id));
        payload.put("finalScores", finalScores);
        broadcast(roomId, "GAME_END", payload);

        persistenceExecutor.execute(() -> {
            if (winnerId != null) {
                chainRoomMapper.updateLivesAndScore(roomId, winnerId, state.getLives(winnerId), WINNER_BONUS_SCORE);
                memberMapper.addPoint(winnerId, WINNER_BONUS_SCORE);
            }
            chainRoomMapper.endRoom(roomId, winnerId);
            for (Map.Entry<Integer, Integer> e : finalRanks.entrySet()) {
                chainRoomMapper.setFinalRank(roomId, e.getKey(), e.getValue());
            }
        });

        rooms.remove(roomId);
        turnCounters.remove(roomId);
        lobbySessions.remove(roomId);
    }

    private LocalDateTime toLocalDateTime(long epochMillis) {
        return LocalDateTime.ofInstant(Instant.ofEpochMilli(epochMillis), ZoneId.systemDefault());
    }
}
