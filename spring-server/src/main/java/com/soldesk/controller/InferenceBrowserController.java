package com.soldesk.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Set;

@RestController
@RequestMapping("/api/sign")
public class InferenceBrowserController {
    private static final Set<String> CAMERA_MODULES = Set.of("hand-camera.js", "api-client.js");
    private static final Set<String> MEDIAPIPE_FILES = Set.of(
        "vision_bundle.mjs", "vision_bundle.mjs.map", "hand_landmarker.task");
    private static final Set<String> WASM_FILES = Set.of(
        "vision_wasm_internal.js", "vision_wasm_internal.wasm",
        "vision_wasm_nosimd_internal.js", "vision_wasm_nosimd_internal.wasm");

    private final HttpClient client = HttpClient.newBuilder().version(HttpClient.Version.HTTP_1_1).connectTimeout(Duration.ofSeconds(5)).build();
    private final URI upstream;

    public InferenceBrowserController(@Value("${python.server.url:http://localhost:8000}") String pythonServerUrl) {
        this.upstream = URI.create(pythonServerUrl);
    }

    @GetMapping("/assets/js/{file}")
    public void cameraModule(@PathVariable("file") String file, HttpServletResponse response) throws IOException {
        asset(CAMERA_MODULES, "/static/js/", file, response);
    }

    @GetMapping("/assets/vendor/mediapipe/{file}")
    public void mediapipe(@PathVariable("file") String file, HttpServletResponse response) throws IOException {
        asset(MEDIAPIPE_FILES, "/static/vendor/mediapipe/", file, response);
    }

    @GetMapping("/assets/vendor/mediapipe/wasm/{file}")
    public void wasm(@PathVariable("file") String file, HttpServletResponse response) throws IOException {
        asset(WASM_FILES, "/static/vendor/mediapipe/wasm/", file, response);
    }

    @PostMapping(path = "/jamo/{operation:predict|coach}", consumes = "application/json")
    public void jamo(@PathVariable("operation") String operation, @RequestBody String body,
                     HttpServletResponse response) throws IOException {
        var request = request("/" + operation)
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build();
        relay(request, response, false);
    }

    private void asset(Set<String> allowed, String directory, String file, HttpServletResponse response) throws IOException {
        if (!allowed.contains(file)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        relay(request(directory + file).GET().build(), response, true);
    }

    private HttpRequest.Builder request(String path) {
        return HttpRequest.newBuilder(upstream.resolve(path)).timeout(Duration.ofSeconds(20));
    }

    private void relay(HttpRequest request, HttpServletResponse response, boolean cacheable) throws IOException {
        HttpResponse<InputStream> result;
        try {
            result = client.send(request, HttpResponse.BodyHandlers.ofInputStream());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Inference request interrupted", e);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Inference server unavailable", e);
        }
        try (InputStream stream = result.body()) {
            response.setStatus(result.statusCode());
            result.headers().firstValue("Content-Type").ifPresent(response::setContentType);
            result.headers().firstValueAsLong("Content-Length").ifPresent(response::setContentLengthLong);
            response.setHeader("Cache-Control", cacheable && result.statusCode() == 200 ? "public, max-age=3600" : "no-store");
            stream.transferTo(response.getOutputStream());
        }
    }
}

