package com.soldesk.service;

import java.io.IOException;
import java.net.SocketTimeoutException;
import java.util.List;

import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.DefaultResponseErrorHandler;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

/** The word-learning API has a different contract from the single-frame jamo API. */
@Service
public class SignLearningApiService {
    public static final long MAX_VIDEO_BYTES = 25L * 1024 * 1024;
    private final RestTemplate client;
    private final String baseUrl;
    private final String apiKey;

    public SignLearningApiService(
            @Value("${python.server.url:http://localhost:8000}") String baseUrl,
            @Value("${sign.api.key:${SIGN_API_KEY:}}") String apiKey,
            @Value("${sign.api.connect-timeout-ms:5000}") int connectTimeout,
            @Value("${sign.api.read-timeout-ms:120000}") int readTimeout) {
        this.baseUrl = baseUrl.replaceAll("/+$", "") + "/api/v1/signs";
        this.apiKey = apiKey;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeout);
        factory.setReadTimeout(readTimeout);
        factory.setBufferRequestBody(false);
        client = new RestTemplate(factory);
        // Inspect upstream statuses ourselves, including video Range responses (416).
        client.setErrorHandler(new DefaultResponseErrorHandler() {
            @Override
            public boolean hasError(ClientHttpResponse response) { return false; }
        });
    }

    public JsonNode chapters(String contextPath) {
        return publicUrls(get("/chapters"), contextPath);
    }

    public JsonNode chapter(String chapterId, String contextPath) {
        requireId(chapterId, "chapter-\\d{2}");
        return publicUrls(get("/chapters/" + chapterId), contextPath);
    }

    public JsonNode word(String wordId, String contextPath) {
        requireId(wordId, "WORD\\d{4}");
        return publicUrls(get("/words/" + wordId), contextPath);
    }

    private JsonNode get(String path) {
        return exchange(path, HttpMethod.GET, new HttpEntity<Void>(headers()));
    }

    public JsonNode evaluate(String wordId, String attemptId, MultipartFile video) {
        requireId(wordId, "WORD\\d{4}");
        requireId(attemptId, "[A-Za-z0-9_-]{1,80}");
        if (video == null || video.isEmpty()) throw new ApiException(422, "촬영한 영상이 없습니다. 다시 녹화해 주세요.");
        if (video.getSize() > MAX_VIDEO_BYTES) throw upstreamError(413);
        String mime = video.getContentType();
        MediaType type;
        try {
            type = MediaType.parseMediaType(mime == null ? "application/octet-stream" : mime);
        } catch (IllegalArgumentException ex) {
            throw upstreamError(422);
        }
        String extension;
        if (type.getType().equals("video") && type.getSubtype().equals("webm")) extension = ".webm";
        else if (type.getType().equals("video") && type.getSubtype().equals("mp4")) extension = ".mp4";
        else throw new ApiException(422, "WebM 또는 MP4 형식으로 촬영해 주세요.");

        HttpHeaders fileHeaders = new HttpHeaders();
        fileHeaders.setContentType(type);
        fileHeaders.setContentDispositionFormData("video", "attempt" + extension);
        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("target_word_id", wordId);
        form.add("attempt_id", attemptId);
        form.add("use_llm", "false");
        form.add("video", new HttpEntity<>(video.getResource(), fileHeaders));
        HttpHeaders requestHeaders = headers();
        requestHeaders.setContentType(MediaType.MULTIPART_FORM_DATA);
        JsonNode result = exchange("/evaluate-video", HttpMethod.POST, new HttpEntity<>(form, requestHeaders));
        if (!attemptId.equals(result.path("attempt_id").asText())
                || !wordId.equals(result.path("target_word_id").asText())
                || !(result.path("status").asText().equals("ok") || result.path("status").asText().equals("retry"))) {
            throw new ApiException(502, "평가 응답을 확인할 수 없습니다. 다시 시도해 주세요.");
        }
        return result;
    }

    public void reference(String wordId, String range, HttpServletResponse response) throws IOException {
        requireId(wordId, "WORD\\d{4}");
        try {
            client.execute(baseUrl + "/reference/" + wordId, HttpMethod.GET, request -> {
                request.getHeaders().putAll(headers());
                if (range != null) request.getHeaders().set(HttpHeaders.RANGE, range);
            }, upstream -> {
                int status = upstream.getRawStatusCode();
                if (status != 200 && status != 206 && status != 416) throw upstreamError(status);
                response.setStatus(status);
                for (String name : List.of("Content-Type", "Content-Length", "Accept-Ranges", "Content-Range")) {
                    String value = upstream.getHeaders().getFirst(name);
                    if (value != null) response.setHeader(name, value);
                }
                // Copy while the upstream response is open; never retain its InputStream.
                upstream.getBody().transferTo(response.getOutputStream());
                return null;
            });
        } catch (ResourceAccessException ex) {
            if (response.isCommitted()) throw new IOException("Video stream interrupted", ex);
            throw connectionError(ex);
        } catch (RestClientException ex) {
            if (response.isCommitted()) throw new IOException("Video stream interrupted", ex);
            throw upstreamError(502);
        }
    }

    private JsonNode exchange(String path, HttpMethod method, HttpEntity<?> request) {
        try {
            // Read errors as text too: upstream validation detail may be a string or an array.
            ResponseEntity<String> response = client.exchange(baseUrl + path, method, request, String.class);
            if (!response.getStatusCode().is2xxSuccessful()) {
                throw upstreamError(response.getStatusCodeValue(), response.getBody());
            }
            JsonNode body = new com.fasterxml.jackson.databind.ObjectMapper().readTree(response.getBody());
            if (body == null || !body.isObject()) throw upstreamError(502);
            return body;
        } catch (ResourceAccessException ex) {
            throw connectionError(ex);
        } catch (RestClientException | IOException | IllegalArgumentException ex) {
            throw upstreamError(502);
        }
    }

    private HttpHeaders headers() {
        HttpHeaders headers = new HttpHeaders();
        if (apiKey != null && !apiKey.isBlank()) headers.set("X-Sign-Api-Key", apiKey);
        return headers;
    }

    private JsonNode publicUrls(JsonNode node, String contextPath) {
        if (node.isObject()) {
            ObjectNode object = (ObjectNode) node;
            String prefix = contextPath + "/api/sign-learning";
            if (object.has("reference_video_url")) object.put("reference_video_url", prefix + "/reference/" + object.path("word_id").asText());
            if (object.has("detail_url")) object.put("detail_url", prefix + "/chapters/" + object.path("chapter_id").asText());
            if (object.has("video_evaluation_url")) object.put("video_evaluation_url", prefix + "/evaluate-video");
            object.remove("evaluation_url"); // Coordinate evaluation is not exposed by this screen.
        }
        if (node.isContainerNode()) node.forEach(child -> publicUrls(child, contextPath));
        return node;
    }

    private static void requireId(String value, String pattern) {
        if (value == null || !value.matches(pattern)) throw new ApiException(422, "학습 요청 형식을 확인해 주세요.");
    }

    private static ApiException connectionError(ResourceAccessException ex) {
        Throwable cause = ex;
        while (cause != null) {
            if (cause instanceof SocketTimeoutException) return new ApiException(504, "평가 응답 시간이 초과됐습니다. 결과를 확인하지 못했으니 잠시 후 다시 시도해 주세요.");
            cause = cause.getCause();
        }
        return new ApiException(502, "학습 서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.");
    }

    private static ApiException upstreamError(int status, String responseBody) {
        if (status == 422 && responseBody != null) {
            try {
                JsonNode body = new com.fasterxml.jackson.databind.ObjectMapper().readTree(responseBody);
                String detail = body == null ? "" : body.path("detail").asText("");
                // Only translate known errors; never expose arbitrary upstream response content.
                switch (detail) {
                    case "Cannot determine video frame rate":
                        return new ApiException(422, "녹화 영상의 프레임 속도 정보를 읽지 못했습니다. 카메라를 껐다 켜고 다시 촬영해 주세요. (VIDEO_FRAME_RATE)");
                    case "Video must be at most 20 seconds":
                        return new ApiException(422, "서버에서 영상 길이를 20초 초과로 판단했습니다. 짧게 촬영해도 반복되면 녹화 영상의 시간 정보 확인이 필요합니다. (VIDEO_DURATION)");
                    case "Video decoding failed":
                        return new ApiException(422, "서버에서 녹화 영상의 화면을 읽지 못했습니다. 다시 촬영해 주세요. 반복되면 녹화 형식 확인이 필요합니다. (VIDEO_DECODE)");
                    case "Maximum resolution is 1920x1080":
                        return new ApiException(422, "녹화 해상도가 서버의 허용 범위를 초과했습니다. 카메라 해상도를 낮춰 주세요. (VIDEO_RESOLUTION)");
                    case "Record at least 2 seconds with your hands visible":
                        return new ApiException(422, "영상에서 분석할 프레임을 충분히 읽지 못했습니다. 2~10초 동안 동작 전체를 다시 촬영해 주세요. (VIDEO_FRAMES)");
                    case "Unknown target_word_id":
                    case "target_word_id is required for evaluation":
                        return new ApiException(422, "분석할 단어를 확인하지 못했습니다. 페이지를 새로고침하고 단어를 다시 선택해 주세요. (VIDEO_WORD)");
                    default:
                        break;
                }
            } catch (IOException ignored) {
                // Preserve the HTTP error even if the upstream body is not valid JSON.
            }
        }
        return upstreamError(status);
    }

    private static ApiException upstreamError(int status) {
        switch (status) {
            case 404: return new ApiException(404, "단어 또는 모범 영상을 찾을 수 없습니다.");
            case 413: return new ApiException(413, "영상이 25MiB를 넘었습니다. 더 짧게 촬영해 주세요.");
            case 422: return new ApiException(422, "영상 분석 요청이 거절되었습니다. 페이지를 새로고침하고 다시 촬영해 주세요. 반복되면 요청 형식 확인이 필요합니다. (VIDEO_REQUEST)");
            case 429: return new ApiException(429, "다른 영상을 분석 중입니다. 잠시 후 같은 영상으로 다시 평가해 주세요.");
            case 503: return new ApiException(503, "수어 학습 모델이 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.");
            default: return new ApiException(502, "학습 서버 응답에 문제가 있습니다. 잠시 후 다시 시도해 주세요.");
        }
    }

    public static class ApiException extends RuntimeException {
        private final int status;
        public ApiException(int status, String message) { super(message); this.status = status; }
        public int getStatus() { return status; }
    }
}
