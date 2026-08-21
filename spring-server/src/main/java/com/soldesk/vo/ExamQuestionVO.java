package com.soldesk.vo;

import java.util.List;

public class ExamQuestionVO {
    private Long signWordId;
    private String word;
    private String type;
    private String description;   // ← 추가
    private List<String> choices;

    public Long getSignWordId() { return signWordId; }
    public void setSignWordId(Long signWordId) { this.signWordId = signWordId; }

    public String getWord() { return word; }
    public void setWord(String word) { this.word = word; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public List<String> getChoices() { return choices; }
    public void setChoices(List<String> choices) { this.choices = choices; }
}