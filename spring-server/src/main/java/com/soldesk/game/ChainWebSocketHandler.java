package com.soldesk.game;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.soldesk.security.CustomUserDetail;
import com.soldesk.service.ChainRoomService;

@Component
public class ChainWebSocketHandler extends TextWebSocketHandler {

    private static final Pattern ROOM_ID_PATTERN = Pattern.compile("/ws/playzone/chain/(\\d+)");

    @Autowired private ChainRoomService chainRoomService;
    @Autowired private ChainGameManager chainGameManager;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long roomId = extractRoomId(session);
        Integer memberId = extractMemberId(session);

        if (roomId == null || memberId == null || !chainRoomService.isParticipant(roomId, memberId)) {
            session.close(CloseStatus.NOT_ACCEPTABLE);
            return;
        }

        session.getAttributes().put("roomId", roomId);
        session.getAttributes().put("memberId", memberId);

        boolean isPlaying = chainGameManager.getState(roomId) != null;
        if (isPlaying) {
            chainGameManager.registerSession(roomId, session);
        } else {
            chainGameManager.registerLobbySession(roomId, session);
        }

        String envelope = objectMapper.writeValueAsString(
            new Envelope("STATE", chainRoomService.buildStateDto(roomId)));
        session.sendMessage(new TextMessage(envelope));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Long roomId = (Long) session.getAttributes().get("roomId");
        if (roomId == null) return;
        chainGameManager.unregisterSession(roomId, session);
        chainGameManager.unregisterLobbySession(roomId, session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // 서버 -> 클라 단방향 브로드캐스트 구조. 클라 액션은 REST(/api/playzone/chain/**)로만 받는다.
    }

    private Long extractRoomId(WebSocketSession session) {
        Matcher m = ROOM_ID_PATTERN.matcher(session.getUri().getPath());
        if (!m.find()) return null;
        return Long.parseLong(m.group(1));
    }

    private Integer extractMemberId(WebSocketSession session) {
        Object ctx = session.getAttributes().get("SPRING_SECURITY_CONTEXT");
        if (!(ctx instanceof SecurityContext)) return null;
        Authentication auth = ((SecurityContext) ctx).getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof CustomUserDetail)) return null;
        return ((CustomUserDetail) auth.getPrincipal()).getMemberId();
    }

    private static class Envelope {
        public String type;
        public Object payload;
        Envelope(String type, Object payload) { this.type = type; this.payload = payload; }
    }
}
