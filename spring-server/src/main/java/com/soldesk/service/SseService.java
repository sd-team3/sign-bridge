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
    private Map<Integer, SseEmitter> sseEmitterMap = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    public SseEmitter subscribe(int id) {
        long timeout = 60L * 1000 * 60;
        SseEmitter sseEmitter = new SseEmitter(timeout);
        sseEmitterMap.put(id, sseEmitter);

        sseEmitter.onCompletion(() -> sseEmitterMap.remove(id));

        sseEmitter.onTimeout(() -> sseEmitter.complete());

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
