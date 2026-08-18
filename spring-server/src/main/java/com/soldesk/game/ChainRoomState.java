package com.soldesk.game;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.locks.ReentrantLock;

import org.springframework.web.socket.WebSocketSession;

import com.soldesk.vo.RecognitionState;

/**
 * DB 에는 없는, 진행 중인 끝말잇기 한 판의 "실시간" 상태.
 * ChainGameManager 가 방(room) 하나당 인스턴스 하나씩 들고 있는다.
 * (프레임 단위로 매우 자주 갱신되므로 매번 DB를 치지 않고 메모리에서 처리하고,
 *  턴이 끝나거나 게임이 끝나는 "의미있는 이벤트" 시점에만 DB에 반영한다.)
 */
public class ChainRoomState {

    private final long roomId;
    private final int turnTimeLimitBaseSec;

    /** 턴 순서대로의 memberId 목록 (탈락해도 목록에서 제거하지 않고 eliminated 로만 표시 - 순서 계산이 쉬워짐) */
    private final List<Integer> turnOrder = new CopyOnWriteArrayList<>();
    private volatile int currentTurnIndex = 0;

    private volatile long turnDeadlineEpochMillis;
    private volatile String requiredFirstChar = null; // null = 이번 판 첫 턴(아무 단어나 가능)

    private final Set<Integer> eliminated = ConcurrentHashMap.newKeySet();
    private final Set<String> usedWords = ConcurrentHashMap.newKeySet();

    /** 현재 턴 플레이어의 자모 조합 상태. 턴이 바뀔 때마다 새로 만든다. */
    private volatile RecognitionState currentComposerState = new RecognitionState();

    private final Set<WebSocketSession> sessions = ConcurrentHashMap.newKeySet();

    private volatile ScheduledFuture<?> timeoutTask;
    private volatile boolean ended = false;

    /** 턴 전환(완료/타임아웃/시작)이 동시에 두 번 처리되지 않도록 보호 */
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

    public Set<String> getUsedWords() { return usedWords; }

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

    /** 다음 살아있는 플레이어의 turnOrder 인덱스를 계산 (현재 인덱스 다음부터 한 바퀴 탐색) */
    public int nextAliveIndex(int fromIndexExclusive) {
        int size = turnOrder.size();
        for (int step = 1; step <= size; step++) {
            int idx = (fromIndexExclusive + step) % size;
            if (!eliminated.contains(turnOrder.get(idx))) {
                return idx;
            }
        }
        return fromIndexExclusive; // 전멸 등 예외 상황 방어
    }

    public LinkedHashSet<Integer> aliveMembersInOrder() {
        LinkedHashSet<Integer> result = new LinkedHashSet<>();
        for (Integer id : turnOrder) {
            if (!eliminated.contains(id)) result.add(id);
        }
        return result;
    }
}
