package com.soldesk.game;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.locks.ReentrantLock;

import org.springframework.web.socket.WebSocketSession;

import com.soldesk.vo.RecognitionState;

public class ChainRoomState {

    private final long roomId;
    private final int turnTimeLimitBaseSec;

    private final List<Integer> turnOrder = new CopyOnWriteArrayList<>();
    private volatile int currentTurnIndex = 0;

    private volatile long turnDeadlineEpochMillis;
    private volatile String requiredFirstChar = null; // null = 이번 판 첫 턴(아무 단어나 가능)

    private final Set<Integer> eliminated = ConcurrentHashMap.newKeySet();
    private final List<Integer> eliminationOrder = new CopyOnWriteArrayList<>();
    private final Set<String> usedWords = ConcurrentHashMap.newKeySet();
    private final Map<Integer, Integer> lives = new ConcurrentHashMap<>();
    private final Map<Integer, Integer> scores = new ConcurrentHashMap<>();

    private volatile RecognitionState currentComposerState = new RecognitionState();

    private final Set<WebSocketSession> sessions = ConcurrentHashMap.newKeySet();

    private volatile ScheduledFuture<?> timeoutTask;
    private volatile boolean ended = false;

    private final ReentrantLock turnLock = new ReentrantLock();

    public ChainRoomState(long roomId, int turnTimeLimitBaseSec) {
        this.roomId = roomId;
        this.turnTimeLimitBaseSec = turnTimeLimitBaseSec;
    }

    public long getRoomId() { return roomId; }
    public int getTurnTimeLimitBaseSec() { return turnTimeLimitBaseSec; }

    public List<Integer> getTurnOrder() { return turnOrder; }
    public void setTurnOrder(List<Integer> order) {
        turnOrder.clear();
        turnOrder.addAll(order);
    }

    public int getCurrentTurnIndex() { return currentTurnIndex; }
    public void setCurrentTurnIndex(int idx) { this.currentTurnIndex = idx; }

    public Integer getCurrentTurnMemberId() {
        if (turnOrder.isEmpty()) return null;
        return turnOrder.get(currentTurnIndex % turnOrder.size());
    }

    public long getTurnDeadlineEpochMillis() { return turnDeadlineEpochMillis; }
    public void setTurnDeadlineEpochMillis(long v) { this.turnDeadlineEpochMillis = v; }

    public void extendDeadline(long millis) { this.turnDeadlineEpochMillis += millis; }

    public String getRequiredFirstChar() { return requiredFirstChar; }
    public void setRequiredFirstChar(String c) { this.requiredFirstChar = c; }

    public Set<Integer> getEliminated() { return eliminated; }
    public boolean isEliminated(int memberId) { return eliminated.contains(memberId); }

    public void markEliminated(int memberId) {
        if (eliminated.add(memberId)) {
            eliminationOrder.add(memberId);
        }
    }

    public List<Integer> getEliminationOrder() { return eliminationOrder; }

    public Set<String> getUsedWords() { return usedWords; }

    public void initLivesAndScore(List<Integer> memberIds) {
        for (Integer id : memberIds) {
            lives.put(id, 3);
            scores.put(id, 0);
        }
    }

    public int getLives(int memberId) { return lives.getOrDefault(memberId, 0); }
    public void setLives(int memberId, int value) { lives.put(memberId, value); }

    public int getScore(int memberId) { return scores.getOrDefault(memberId, 0); }
    public int addScore(int memberId, int delta) {
        return scores.merge(memberId, delta, Integer::sum);
    }

    public RecognitionState getCurrentComposerState() { return currentComposerState; }
    public void resetComposerState() { this.currentComposerState = new RecognitionState(); }

    public Set<WebSocketSession> getSessions() { return sessions; }

    public ScheduledFuture<?> getTimeoutTask() { return timeoutTask; }
    public void setTimeoutTask(ScheduledFuture<?> task) {
        if (this.timeoutTask != null) {
            this.timeoutTask.cancel(false);
        }
        this.timeoutTask = task;
    }

    public boolean isEnded() { return ended; }
    public void setEnded(boolean ended) { this.ended = ended; }

    public ReentrantLock getTurnLock() { return turnLock; }

    /** 아직 탈락하지 않은 참가자 수 */
    public long aliveCount() {
        return turnOrder.stream().distinct().filter(id -> !eliminated.contains(id)).count();
    }

    public int nextAliveIndex(int fromIndexExclusive) {
        int size = turnOrder.size();
        for (int step = 1; step <= size; step++) {
            int idx = (fromIndexExclusive + step) % size;
            if (!eliminated.contains(turnOrder.get(idx))) {
                return idx;
            }
        }
        return fromIndexExclusive;
    }

    public LinkedHashSet<Integer> aliveMembersInOrder() {
        LinkedHashSet<Integer> result = new LinkedHashSet<>();
        for (Integer id : turnOrder) {
            if (!eliminated.contains(id)) result.add(id);
        }
        return result;
    }
}
