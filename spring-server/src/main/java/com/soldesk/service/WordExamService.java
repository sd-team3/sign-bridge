package com.soldesk.service;

import java.time.Instant;
import java.util.*;
import java.util.function.Consumer;
import org.springframework.stereotype.Service;
import org.springframework.context.annotation.DependsOn;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.multipart.MultipartFile;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.node.*;
import com.soldesk.mapper.WordExamMapper;
import com.soldesk.service.SignLearningApiService.ApiException;

@Service
@DependsOn("wordExamSchema")
public class WordExamService {
    private final WordExamMapper mapper;
    private final SignLearningApiService learning;
    private final TransactionTemplate transaction;
    private final ObjectMapper json = new ObjectMapper();
    private static final String POLICY = "word-practice-v1";

    public WordExamService(WordExamMapper mapper, SignLearningApiService learning, PlatformTransactionManager manager) {
        this.mapper = mapper;
        this.learning = learning;
        this.transaction = new TransactionTemplate(manager);
    }

    private ObjectNode parse(String payload) {
        if (payload == null) throw new ApiException(404, "시험을 찾을 수 없습니다.");
        try { return (ObjectNode) json.readTree(payload); }
        catch (Exception ex) { throw new ApiException(500, "시험 기록을 읽지 못했습니다."); }
    }

    public JsonNode start(int member, String mode, String chapter, String reviewId) {
        if (!Set.of("choice", "motion", "both").contains(mode)) throw new ApiException(422, "시험 방식을 선택해 주세요.");
        JsonNode catalog = learning.chapters("");
        List<JsonNode> all = new ArrayList<>();
        List<List<JsonNode>> groups = new ArrayList<>();
        for (JsonNode c : catalog.path("chapters")) {
            JsonNode detail = learning.chapter(c.path("chapter_id").asText(), "");
            List<JsonNode> group = new ArrayList<>();
            detail.path("words").forEach(w -> { all.add(w); group.add(w); });
            groups.add(group);
        }
        if (all.size() != 70 || groups.size() != 7 || all.stream().map(w -> w.path("word_id").asText()).distinct().count() != 70)
            throw new ApiException(503, "기본 70단어 시험 과정을 확인하지 못했습니다.");
        List<JsonNode> selected = new ArrayList<>();
        String scope = "전체 7개 챕터";
        if (reviewId != null && !reviewId.isBlank()) {
            ObjectNode previous = parse(mapper.find(reviewId, member));
            if (!previous.path("finished").asBoolean()) throw new ApiException(409, "종료된 시험에서 복습을 시작해 주세요.");
            Set<String> retry = new HashSet<>();
            for (JsonNode q : previous.path("questions")) if (!q.path("verdict").asText().equals("correct")) retry.add(q.path("word_id").asText());
            for (JsonNode w : all) if (retry.contains(w.path("word_id").asText())) selected.add(w);
            Collections.shuffle(selected);
            selected = new ArrayList<>(selected.subList(0, Math.min(10, selected.size())));
            scope = "다시 연습할 단어";
        } else if (chapter != null && !chapter.isBlank()) {
            for (JsonNode w : all) if (chapter.equals(w.path("chapter_id").asText())) selected.add(w);
            scope = chapter;
            for (JsonNode c : catalog.path("chapters")) if (chapter.equals(c.path("chapter_id").asText())) scope = c.path("title").asText();
        } else {
            for (List<JsonNode> group : groups) {
                Collections.shuffle(group);
                selected.addAll(group.subList(0, Math.min(2, group.size())));
            }
        }
        if (selected.isEmpty()) throw new ApiException(422, "출제할 단어가 없습니다.");
        if (chapter != null && !chapter.isBlank() || reviewId != null && !reviewId.isBlank()) Collections.shuffle(selected);
        ObjectNode exam = json.createObjectNode();
        String id = UUID.randomUUID().toString();
        exam.put("id", id).put("scope", scope).put("mode", mode).put("curriculum_version", catalog.path("curriculum_version").asText())
            .put("policy_version", POLICY).put("started_at", Instant.now().toString()).put("finished", false);
        exam.put("recognition_threshold", .7);
        ArrayNode questions = exam.putArray("questions");
        for (int i = 0; i < selected.size(); i++) {
            JsonNode word = selected.get(i);
            boolean motion = mode.equals("motion") || mode.equals("both") && i % 2 == 1;
            ObjectNode q = questions.addObject();
            q.put("number", i).put("word_id", word.path("word_id").asText()).put("label", word.path("label").asText())
                .put("chapter_id", word.path("chapter_id").asText()).put("type", motion ? "motion" : "choice").put("attempts", 0);
            if (!motion) {
                List<JsonNode> others = new ArrayList<>();
                for (JsonNode w : all) if (!w.path("label").asText().equals(word.path("label").asText())) others.add(w);
                Collections.shuffle(others);
                List<JsonNode> choices = new ArrayList<>(others.subList(0, 3));
                choices.add(word); Collections.shuffle(choices);
                ArrayNode options = q.putArray("choices");
                for (JsonNode w : choices) options.addObject().put("id", w.path("word_id").asText()).put("label", w.path("label").asText());
            }
        }
        mapper.insert(id, member, exam.toString());
        return visible(exam);
    }

    public JsonNode get(String id, int member) { return visible(parse(mapper.find(id, member))); }

    public String referenceWord(String id, int member, int number) {
        ObjectNode exam = parse(mapper.find(id, member));
        if (number < 0 || number >= exam.path("questions").size()) throw new ApiException(404, "문제를 찾을 수 없습니다.");
        JsonNode q = exam.path("questions").get(number);
        if (!exam.path("finished").asBoolean() && !q.path("type").asText().equals("choice"))
            throw new ApiException(409, "동작 표현의 모범 영상은 시험 종료 후 볼 수 있습니다.");
        return q.path("word_id").asText();
    }

    private JsonNode mutate(String id, int member, Consumer<ObjectNode> action) {
        return transaction.execute(status -> {
            ObjectNode exam = parse(mapper.lock(id, member));
            action.accept(exam);
            mapper.update(id, member, exam.toString());
            return visible(exam);
        });
    }

    private ObjectNode question(ObjectNode exam, int number) {
        if (exam.path("finished").asBoolean()) throw new ApiException(409, "이미 종료된 시험입니다.");
        if (number < 0 || number >= exam.path("questions").size()) throw new ApiException(422, "문제 번호를 확인해 주세요.");
        for (int i = 0; i < number; i++) if (!exam.path("questions").get(i).has("verdict")) throw new ApiException(409, "앞 문제부터 제출해 주세요.");
        return (ObjectNode) exam.path("questions").get(number);
    }

    public JsonNode choice(String id, int member, int number, String answer) {
        return mutate(id, member, exam -> {
            ObjectNode q = question(exam, number);
            if (!q.path("type").asText().equals("choice")) throw new ApiException(422, "영상 이해 문제에서 답을 선택해 주세요.");
            if (q.has("verdict")) return;
            boolean valid = false;
            for (JsonNode option : q.path("choices")) if (answer.equals(option.path("id").asText())) valid = true;
            if (!valid) throw new ApiException(422, "보기에서 답을 선택해 주세요.");
            q.put("answer", answer).put("verdict", answer.equals(q.path("word_id").asText()) ? "correct" : "incorrect");
        });
    }

    public JsonNode motion(String id, int member, int number, String attempt, MultipartFile video) {
        if (attempt == null || !attempt.matches("[A-Za-z0-9_-]{1,80}")) throw new ApiException(422, "촬영 요청 번호를 확인해 주세요.");
        return mutate(id, member, exam -> {
            ObjectNode q = question(exam, number);
            if (!q.path("type").asText().equals("motion")) throw new ApiException(422, "동작 표현 문제에서 영상을 제출해 주세요.");
            if (q.has("verdict") && !q.path("verdict").asText().equals("pending")) return;
            if (attempt.equals(q.path("attempt_id").asText())) return;
            if (q.path("attempts").asInt() >= 3) throw new ApiException(409, "세 번 촬영했어요. 이 단어는 나중에 다시 연습하고 다음 문제로 넘어가 주세요.");
            JsonNode result = learning.evaluate(q.path("word_id").asText(), attempt, video);
            String modelId = result.path("model_id").asText();
            if (modelId.isBlank()) throw new ApiException(502, "평가 모델 정보를 확인하지 못했습니다.");
            if (exam.has("model_id") && !exam.path("model_id").asText().equals(modelId))
                throw new ApiException(409, "시험 중 평가 모델이 변경됐습니다. 새 시험을 시작해 주세요.");
            exam.put("model_id", modelId);
            q.put("attempt_id", attempt).put("attempts", q.path("attempts").asInt() + 1);
            q.set("evaluation", result);
            q.put("verdict", motionVerdict(result));
        });
    }

    public static String motionVerdict(JsonNode result) {
        JsonNode r = result.path("recognition");
        String reason = result.path("feedback").path("reason").asText();
        if (!result.path("status").asText().equals("ok") || !r.isObject()
                || Set.of("insufficient_tracking", "insufficient_comparison", "reference_unavailable").contains(reason)) return "pending";
        JsonNode top = r.path("top3");
        double confidence = top.isArray() && !top.isEmpty() ? top.get(0).path("score").asDouble(-1) : -1;
        if (!Double.isFinite(confidence) || confidence < .7 || confidence > 1 || !r.path("target_matches_top1").isBoolean()) return "pending";
        return r.path("target_matches_top1").asBoolean() ? "correct" : "incorrect";
    }

    public JsonNode skip(String id, int member, int number) {
        return mutate(id, member, exam -> {
            ObjectNode q = question(exam, number);
            if (!q.has("verdict")) q.put("verdict", "pending");
        });
    }

    public JsonNode finish(String id, int member) {
        return mutate(id, member, exam -> {
            if (exam.path("finished").asBoolean()) return;
            for (JsonNode q : exam.path("questions")) if (!q.has("verdict")) throw new ApiException(409, "모든 문제에 응답해 주세요.");
            exam.put("finished", true).put("finished_at", Instant.now().toString());
        });
    }

    public JsonNode history(int member) {
        ArrayNode list = json.createArrayNode();
        for (String payload : mapper.history(member)) {
            ObjectNode exam = parse(payload);
            ObjectNode item = exam.deepCopy();
            item.remove("questions");
            item.put("count", exam.path("questions").size());
            list.add(item);
        }
        return list;
    }

    private ObjectNode visible(ObjectNode stored) {
        ObjectNode exam = stored.deepCopy();
        if (exam.path("finished").asBoolean()) {
            ObjectNode summary = exam.putObject("summary");
            boolean complete = true;
            for (String type : List.of("choice", "motion")) {
                int count = 0, correct = 0, pending = 0;
                for (JsonNode q : exam.path("questions")) if (q.path("type").asText().equals(type)) {
                    count++;
                    if (q.path("verdict").asText().equals("correct")) correct++;
                    if (q.path("verdict").asText().equals("pending")) pending++;
                }
                ObjectNode section = summary.putObject(type).put("count", count).put("correct", correct).put("pending", pending).put("incorrect", count-correct-pending);
                if (type.equals("choice") && count > 0 && pending == 0) section.put("score", Math.round(correct*100.0/count));
                else section.putNull("score");
                complete &= pending == 0;
            }
            summary.put("complete", complete);
        }
        if (!exam.path("finished").asBoolean()) for (JsonNode node : exam.path("questions")) {
            ObjectNode q = (ObjectNode) node;
            if (q.path("type").asText().equals("choice")) q.remove(List.of("word_id", "label"));
            if (q.path("type").asText().equals("choice")) q.remove("verdict");
            q.remove("evaluation");
            q.put("submitted", node.has("answer") || stored.path("questions").get(q.path("number").asInt()).has("verdict"));
            if (q.path("type").asText().equals("motion") && q.has("verdict") && !q.path("verdict").asText().equals("pending")) q.put("verdict", "submitted");
            q.remove("answer");
        }
        return exam;
    }
}
