package com.soldesk.controller;

import java.io.IOException;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.fasterxml.jackson.databind.JsonNode;
import com.soldesk.service.SignLearningApiService;
import com.soldesk.service.SignLearningApiService.ApiException;

@RestController
@RequestMapping("/api/sign-learning")
public class SignLearningAPIController {
    private final SignLearningApiService service;
    public SignLearningAPIController(SignLearningApiService service) { this.service = service; }

    @GetMapping("/chapters")
    public JsonNode chapters(HttpServletRequest request) { return service.chapters(request.getContextPath()); }

    @GetMapping("/chapters/{chapterId}")
    public JsonNode chapter(@PathVariable("chapterId") String chapterId, HttpServletRequest request) {
        return service.chapter(chapterId, request.getContextPath());
    }

    @GetMapping("/words/{wordId}")
    public JsonNode word(@PathVariable("wordId") String wordId, HttpServletRequest request) {
        return service.word(wordId, request.getContextPath());
    }

    @GetMapping("/reference/{wordId}")
    public void reference(@PathVariable("wordId") String wordId,
            @RequestHeader(value = "Range", required = false) String range, HttpServletResponse response) throws IOException {
        service.reference(wordId, range, response);
    }

    @PostMapping(value = "/evaluate-video", consumes = "multipart/form-data")
    public JsonNode evaluate(@RequestParam("target_word_id") String wordId,
            @RequestParam("attempt_id") String attemptId, @RequestParam("video") MultipartFile video) {
        return service.evaluate(wordId, attemptId, video);
    }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Map<String, String>> error(ApiException ex) {
        return ResponseEntity.status(ex.getStatus()).body(Map.of("message", ex.getMessage()));
    }
}
