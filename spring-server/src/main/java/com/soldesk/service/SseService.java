package com.soldesk.service;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class SseService {
    // 만약 알림이 더 필요하다면 밑에 Map을 repository 파일 만들어서 한꺼번에 저장 해야됨
    private Map<Integer, SseEmitter> sseEmitterMap = new ConcurrentHashMap<>(); // id 별 emitter 보관
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    public SseEmitter subscribe(int id) {
        long timeout = 60L * 1000 * 60;
        SseEmitter sseEmitter = new SseEmitter(timeout);
        sseEmitterMap.put(id, sseEmitter);
        // 연결 완료되면 삭제
        sseEmitter.onCompletion(() -> sseEmitterMap.remove(id));
        // 타임아웃 발생하면 complete 실행
        sseEmitter.onTimeout(() -> sseEmitter.complete());
        // 에러
        sseEmitter.onError(error -> sseEmitter.complete());

        sendToClient(id, "connect", "sse Connect");

        return sseEmitter;
    }

    public void sendToClient(int id, String eventName, Object message) {
    SseEmitter sseEmitter = sseEmitterMap.get(id);
    if (sseEmitter == null) {
        return;
    }
    try {
        Map<String, Object> payload = new HashMap<>();
        payload.put("message", message);

        String json = objectMapper.writeValueAsString(payload);

        sseEmitter.send(
            SseEmitter.event()
                        .id(String.valueOf(id))
                        .name(eventName)
                        .data(json, MediaType.valueOf("application/json;charset=UTF-8"))
        );
    } catch (IOException e) {
        sseEmitterMap.remove(id);
    }
}
}
