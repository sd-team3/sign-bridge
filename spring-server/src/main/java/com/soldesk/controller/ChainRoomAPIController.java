package com.soldesk.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.soldesk.dto.ChainFrameRequest;
import com.soldesk.dto.ChainFrameResponse;
import com.soldesk.dto.ChainRoomCreateRequest;
import com.soldesk.dto.ChainRoomStateDto;
import com.soldesk.game.ChainGameManager;
import com.soldesk.service.ChainRoomService;
import com.soldesk.util.SecurityUtil;
import com.soldesk.vo.ChainRoomVO;

@RestController
@RequestMapping("/api/playzone/chain")
public class ChainRoomAPIController {

    @Autowired private ChainRoomService chainRoomService;
    @Autowired private ChainGameManager chainGameManager;
    @Autowired private SecurityUtil securityUtil;

    @GetMapping("/rooms")
    public List<ChainRoomVO> list() {
        return chainRoomService.findWaitingRooms();
    }

    @PostMapping("/rooms")
    public ChainRoomVO create(@RequestBody ChainRoomCreateRequest req) {
        return chainRoomService.createRoom(currentMemberId(), req);
    }

    @GetMapping("/rooms/{roomId}")
    public ChainRoomStateDto detail(@PathVariable long roomId) {
        ChainRoomStateDto dto = chainRoomService.buildStateDto(roomId);
        if ("ENDED".equals(dto.getStatus()) && !chainRoomService.isParticipant(roomId, currentMemberId())) {
            throw new IllegalStateException("참가자만 열람할 수 있습니다.");
        }
        return dto;
    }

    @PostMapping("/rooms/{roomId}/join")
    public ResponseEntity<Void> join(@PathVariable long roomId) {
        chainRoomService.joinRoom(roomId, currentMemberId());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/rooms/{roomId}/leave")
    public ResponseEntity<Void> leave(@PathVariable long roomId) {
        chainRoomService.leaveRoom(roomId, currentMemberId());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/rooms/{roomId}/start")
    public ResponseEntity<Void> start(@PathVariable long roomId) {
        chainRoomService.startRoom(roomId, currentMemberId());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/rooms/{roomId}/frame")
    public ChainFrameResponse frame(@PathVariable long roomId, @RequestBody ChainFrameRequest req) {
        return chainGameManager.processFrame(roomId, currentMemberId(), req.getLandmarks(), req.isMirror());
    }

    @PostMapping("/rooms/{roomId}/complete")
    public ResponseEntity<Void> complete(@PathVariable long roomId) {
        chainGameManager.submitComplete(roomId, currentMemberId());
        return ResponseEntity.ok().build();
    }

    private int currentMemberId() {
        Integer id = securityUtil.getCurrentMemberId();
        if (id == null) throw new IllegalStateException("로그인이 필요합니다.");
        return id;
    }
}
