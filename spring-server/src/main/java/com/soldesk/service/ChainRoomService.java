package com.soldesk.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.soldesk.dto.ChainRoomCreateRequest;
import com.soldesk.dto.ChainRoomStateDto;
import com.soldesk.dto.ChainRoomStateDto.ChainRoomMemberDto;
import com.soldesk.game.ChainGameManager;
import com.soldesk.game.ChainRoomState;
import com.soldesk.mapper.ChainRoomMapper;
import com.soldesk.vo.ChainRoomMemberVO;
import com.soldesk.vo.ChainRoomVO;

@Service
public class ChainRoomService implements InitializingBean {

    private static final int MAX_CAPACITY = 4; // 요구사항 1

    @Autowired private ChainRoomMapper chainRoomMapper;
    @Autowired private com.soldesk.mapper.ChainWordLogMapper chainWordLogMapper;
    @Autowired private ChainGameManager chainGameManager;
    @Autowired private ChainWordValidationService chainWordValidationService;

    /**
     * 서버가 비정상 종료됐다가 재시작된 경우, PLAYING 상태로 남아있는 방은
     * 메모리 상태(ChainGameManager)가 전부 유실된 상태라 진행이 불가능하다.
     * 복구를 시도하는 대신 아예 무효 처리(삭제)해서 별도 복구 로직을 두지 않는다.
     */
    @Override
    public void afterPropertiesSet() {
        List<Long> stuckRoomIds = chainRoomMapper.findRoomIdsByStatus(ChainRoomVO.STATUS_PLAYING);
        if (stuckRoomIds.isEmpty()) return;
        chainWordLogMapper.deleteLogsByRoomIds(stuckRoomIds);
        chainRoomMapper.deleteMembersByRoomIds(stuckRoomIds);
        chainRoomMapper.deleteRoomsByStatus(ChainRoomVO.STATUS_PLAYING);
    }

    @Transactional
    public ChainRoomVO createRoom(int hostMemberId, ChainRoomCreateRequest req) {
        int capacity = req.getChainRoomCapacity() == null
                ? MAX_CAPACITY
                : Math.min(MAX_CAPACITY, Math.max(2, req.getChainRoomCapacity()));

        ChainRoomVO room = new ChainRoomVO();
        room.setChainRoomName(
            (req.getChainRoomName() == null || req.getChainRoomName().isBlank())
                ? "끝말잇기 방" : req.getChainRoomName());
        room.setChainRoomCapacity(capacity);
        room.setTurnTimeLimitBaseSec(8);
        room.setHostMemberId(hostMemberId);
        chainRoomMapper.insertRoom(room);

        ChainRoomMemberVO member = new ChainRoomMemberVO();
        member.setChainRoomId(room.getChainRoomId());
        member.setMemberId(hostMemberId);
        member.setTurnNo(1);
        chainRoomMapper.insertRoomMember(member);

        return chainRoomMapper.findRoomById(room.getChainRoomId());
    }

    public List<ChainRoomVO> findWaitingRooms() {
        return chainRoomMapper.findWaitingRooms();
    }

    @Transactional
    public void joinRoom(long roomId, int memberId) {
        ChainRoomVO room = requireRoom(roomId);
        if (!ChainRoomVO.STATUS_WAITING.equals(room.getStatus())) {
            throw new IllegalStateException("이미 시작되었거나 종료된 방입니다.");
        }
        if (chainRoomMapper.findRoomMember(roomId, memberId) != null) {
            return; // 이미 참여 중
        }
        int count = chainRoomMapper.countRoomMembers(roomId);
        if (count >= room.getChainRoomCapacity()) {
            throw new IllegalStateException("방 인원이 가득 찼습니다.");
        }
        Integer maxTurnNo = chainRoomMapper.findMaxTurnNo(roomId);
        ChainRoomMemberVO member = new ChainRoomMemberVO();
        member.setChainRoomId(roomId);
        member.setMemberId(memberId);
        member.setTurnNo((maxTurnNo == null ? 0 : maxTurnNo) + 1);
        chainRoomMapper.insertRoomMember(member);

        chainGameManager.broadcastLobby(roomId, "ROOM_UPDATE", buildStateDto(roomId));
    }

    @Transactional
    public void leaveRoom(long roomId, int memberId) {
        ChainRoomVO room = requireRoom(roomId);
        chainRoomMapper.deleteRoomMember(roomId, memberId);
        int remaining = chainRoomMapper.countRoomMembers(roomId);

        if (remaining == 0) {
            chainRoomMapper.deleteRoom(roomId);
            return;
        }
        if (room.getHostMemberId() == memberId) {
            List<ChainRoomMemberVO> members = chainRoomMapper.findMembersByRoom(roomId);
            if (!members.isEmpty()) {
                chainRoomMapper.updateHost(roomId, members.get(0).getMemberId());
            }
        }
        chainGameManager.broadcastLobby(roomId, "ROOM_UPDATE", buildStateDto(roomId));
    }

    @Transactional
    public void startRoom(long roomId, int requesterId) {
        ChainRoomVO room = requireRoom(roomId);
        if (room.getHostMemberId() != requesterId) {
            throw new IllegalStateException("방장만 게임을 시작할 수 있습니다.");
        }
        if (!ChainRoomVO.STATUS_WAITING.equals(room.getStatus())) {
            throw new IllegalStateException("이미 시작된 방입니다.");
        }
        List<ChainRoomMemberVO> members = chainRoomMapper.findMembersByRoom(roomId);
        if (members.size() < 2) {
            throw new IllegalStateException("최소 2명 이상이어야 시작할 수 있습니다.");
        }

        List<Integer> order = new ArrayList<>();
        for (ChainRoomMemberVO m : members) order.add(m.getMemberId());

        LocalDateTime deadline = LocalDateTime.now().plusSeconds(room.getTurnTimeLimitBaseSec());
        chainRoomMapper.startRoom(roomId, order.get(0), deadline);

        chainGameManager.startGame(roomId, order, room.getTurnTimeLimitBaseSec());
    }

    private ChainRoomVO requireRoom(long roomId) {
        ChainRoomVO room = chainRoomMapper.findRoomById(roomId);
        if (room == null) throw new IllegalArgumentException("존재하지 않는 방입니다.");
        return room;
    }

    public boolean isParticipant(long roomId, int memberId) {
        return chainRoomMapper.isRoomParticipant(roomId, memberId);
    }

    public java.util.Map<String, Object> myChainHistory(int memberId, int page) {
        int pageSize = 10;
        int offset = Math.max(0, page - 1) * pageSize;
        List<ChainRoomVO> rooms = chainRoomMapper.findEndedRoomsByMember(memberId, offset, pageSize);
        int total = chainRoomMapper.countEndedRoomsByMember(memberId);

        java.util.Map<String, Object> result = new java.util.HashMap<>();
        result.put("rooms", rooms);
        result.put("total", total);
        result.put("page", page);
        result.put("pageSize", pageSize);
        return result;
    }

    public java.util.Map<String, Object> chainHistoryDetail(long roomId, int requesterId) {
        if (!isParticipant(roomId, requesterId)) {
            throw new IllegalStateException("참가자만 열람할 수 있습니다.");
        }
        ChainRoomVO room = requireRoom(roomId);
        List<ChainRoomMemberVO> members = chainRoomMapper.findMembersByRoom(roomId);
        members.sort((a, b) -> {
            Integer ra = a.getFinalRank() == null ? Integer.MAX_VALUE : a.getFinalRank();
            Integer rb = b.getFinalRank() == null ? Integer.MAX_VALUE : b.getFinalRank();
            return ra.compareTo(rb);
        });

        java.util.Map<String, Object> result = new java.util.HashMap<>();
        result.put("room", room);
        result.put("members", members);
        result.put("wordLogs", chainWordLogMapper.findLogsByRoom(roomId));
        return result;
    }

    /** REST 조회 / WS 최초 접속 시 스냅샷 응답용 */
    public ChainRoomStateDto buildStateDto(long roomId) {
        ChainRoomVO room = requireRoom(roomId);
        List<ChainRoomMemberVO> members = chainRoomMapper.findMembersByRoom(roomId);
        ChainRoomState live = chainGameManager.getState(roomId);

        ChainRoomStateDto dto = new ChainRoomStateDto();
        dto.setChainRoomId(room.getChainRoomId());
        dto.setChainRoomName(room.getChainRoomName());
        dto.setStatus(room.getStatus());
        dto.setChainRoomCapacity(room.getChainRoomCapacity());
        dto.setTurnTimeLimitBaseSec(room.getTurnTimeLimitBaseSec());
        dto.setHostMemberId(room.getHostMemberId());
        dto.setWinnerMemberId(room.getWinnerMemberId());

        if (live != null) {
            dto.setCurrentTurnMemberId(live.getCurrentTurnMemberId());
            dto.setDeadlineEpochMillis(live.getTurnDeadlineEpochMillis());
            dto.setRequiredFirstChar(live.getRequiredFirstChar());
            dto.setAlternativeFirstChar(chainWordValidationService.alternativeFirstChar(live.getRequiredFirstChar()));
        } else {
            dto.setCurrentTurnMemberId(room.getCurrentTurnMemberId());
            dto.setRequiredFirstChar(null);
        }

        List<ChainRoomMemberDto> memberDtos = new ArrayList<>();
        for (ChainRoomMemberVO m : members) {
            ChainRoomMemberDto md = new ChainRoomMemberDto();
            md.setMemberId(m.getMemberId());
            md.setMemberName(m.getMemberName());
            md.setMemberProfileImage(m.getMemberProfileImage());
            md.setTurnNo(m.getTurnNo());
            md.setLives(m.getLives());
            md.setScore(m.getScore());
            md.setEliminated(m.isEliminated());
            md.setFinalRank(m.getFinalRank());
            memberDtos.add(md);
        }
        dto.setMembers(memberDtos);
        return dto;
    }
}
