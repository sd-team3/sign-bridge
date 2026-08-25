package com.soldesk.util;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class HangulComposer {
    private static final long MERGE_WINDOW_MS = 3000;

    // 초성 합성 규칙
    private static final Map<Character, Character> TENSE_CHO = new HashMap<>();
    // 종성 합성 규칙
    // (ㄸ, ㅃ, ㅉ 제외)
    private static final Map<Character, Character> TENSE_JONG = new HashMap<>();
    // 이중모음 합성 규칙
    private static final Map<String, Character> VOWEL_COMBO = new HashMap<>();
    static {
        TENSE_CHO.put('ㄱ', 'ㄲ');
        TENSE_CHO.put('ㄷ', 'ㄸ');
        TENSE_CHO.put('ㅂ', 'ㅃ');
        TENSE_CHO.put('ㅅ', 'ㅆ');
        TENSE_CHO.put('ㅈ', 'ㅉ');

        TENSE_JONG.put('ㄱ', 'ㄲ');
        TENSE_JONG.put('ㅅ', 'ㅆ');

        VOWEL_COMBO.put("ㅗㅏ", 'ㅘ');
        VOWEL_COMBO.put("ㅗㅐ", 'ㅙ');
        VOWEL_COMBO.put("ㅗㅣ", 'ㅚ');
        VOWEL_COMBO.put("ㅜㅓ", 'ㅝ');
        VOWEL_COMBO.put("ㅜㅔ", 'ㅞ');
        VOWEL_COMBO.put("ㅜㅣ", 'ㅟ');
        VOWEL_COMBO.put("ㅡㅣ", 'ㅢ');
    }

    private static final char[] CHOSUNG = {
        'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
        'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    };
    private static final char[] JUNGSUNG = {
        'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ',
        'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ'
    };
    private static final char[] JONGSUNG = {
        0, 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ',
        'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ',
        'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    };

    private static final Set<Character> CONSONANTS = new HashSet<>();
    private static final Set<Character> VOWELS = new HashSet<>();
    static {
        for (char c : CHOSUNG) CONSONANTS.add(c);
        for (char c : JUNGSUNG) VOWELS.add(c);
    }

    private final StringBuilder finalized = new StringBuilder();
    private Character cho = null;
    private Character jung = null;
    private Character jong = null;

    private long lastConfirmedAt = 0L;

    public synchronized void addJamo(char jamo) {
        addJamo(jamo, System.currentTimeMillis());
    }

    public synchronized void addJamo(char jamo, long nowMs) {
        if (CONSONANTS.contains(jamo)) {
            handleConsonant(jamo, nowMs);
        } else if (VOWELS.contains(jamo)) {
            handleVowel(jamo, nowMs);
        }
    }

    private void handleConsonant(char c, long now) {
        boolean withinMergeWindow = (now - lastConfirmedAt) < MERGE_WINDOW_MS;

        if (cho == null) {
            cho = c; // 새 음절 시작
        } else if (jung == null) {
            // 초성만 있는 상태에서 자음이 또 옴
            if (withinMergeWindow && c == cho && TENSE_CHO.containsKey(c)) {
                cho = TENSE_CHO.get(c);
            } else {
                // 3초 이상 텀
                flushOrphanChosung();
                cho = c;
            }
        } else if (jong == null) {
            jong = c; // 받침 후보
        } else {
            if (withinMergeWindow && c == jong && TENSE_JONG.containsKey(c)) {
                // 받침 위치에서 3초 이내 같은 자음 반복
                jong = TENSE_JONG.get(c);
            } else {
                // 3초 이상 텀
                commitSyllable();
                cho = c;
            }
        }
        lastConfirmedAt = now;
    }

    private void handleVowel(char v, long now) {
        boolean withinMergeWindow = (now - lastConfirmedAt) < MERGE_WINDOW_MS;

        if (cho == null) {
            finalized.append(v);
        } else if (jung == null) {
            jung = v; // 중성 확정
        } else if (jong == null) {
            String comboKey = "" + jung + v;
            if (withinMergeWindow && VOWEL_COMBO.containsKey(comboKey)) {
                jung = VOWEL_COMBO.get(comboKey);
            } else {
                commitSyllable();
                finalized.append(v);
            }
        } else {
            char movedJong = jong;
            jong = null;
            commitSyllable(); // 종성 없이 확정
            cho = movedJong;
            jung = v;
        }
        lastConfirmedAt = now;
    }

    private void flushOrphanChosung() {
        if (cho != null) {
            finalized.append((char) cho);
        }
        cho = null;
        jung = null;
        jong = null;
    }

    private void commitSyllable() {
        if (cho == null) return;
        if (jung == null) {
            finalized.append((char) cho);
        } else {
            int choIdx = indexOf(CHOSUNG, cho);
            int jungIdx = indexOf(JUNGSUNG, jung);
            int jongIdx = (jong == null) ? 0 : indexOf(JONGSUNG, jong);
            if (choIdx < 0 || jungIdx < 0) {
                finalized.append((char) cho).append((char) jung);
                if (jong != null) finalized.append((char) jong);
            } else {
                char syllable = (char) (0xAC00 + (choIdx * 21 + jungIdx) * 28 + Math.max(jongIdx, 0));
                finalized.append(syllable);
            }
        }
        cho = null;
        jung = null;
        jong = null;
    }

    public synchronized String getText() {
        StringBuilder preview = new StringBuilder(finalized);
        if (cho != null) {
            if (jung == null) {
                preview.append((char) cho);
            } else {
                int choIdx = indexOf(CHOSUNG, cho);
                int jungIdx = indexOf(JUNGSUNG, jung);
                int jongIdx = (jong == null) ? 0 : indexOf(JONGSUNG, jong);
                if (choIdx >= 0 && jungIdx >= 0) {
                    preview.append((char) (0xAC00 + (choIdx * 21 + jungIdx) * 28 + Math.max(jongIdx, 0)));
                }
            }
        }
        return preview.toString();
    }

    public synchronized void commitPending() {
        if (cho != null) {
            if (jung == null) flushOrphanChosung();
            else commitSyllable();
        }
    }

    public synchronized void appendSpace() {
        commitPending();
        finalized.append(' ');
    }

    public synchronized void reset() {
        finalized.setLength(0);
        cho = null;
        jung = null;
        jong = null;
        lastConfirmedAt = 0L;
    }

    private static int indexOf(char[] arr, char c) {
        for (int i = 0; i < arr.length; i++) {
            if (arr[i] == c) return i;
        }
        return -1;
    }
}