package com.soldesk.util;

import java.util.HashSet;
import java.util.Set;

/**
 * 확정된 자모(초성/중성/종성 후보)를 순서대로 받아 완성형 한글 음절로 조합한다.
 *
 * 표준 2벌식 IME와 동일한 규칙을 따른다:
 *  - 초성만 있고 모음이 안 온 상태에서 자음이 또 오면, 이전 초성은 낱자로 확정하고 새 음절 시작
 *  - 초성+중성 상태에서 자음이 오면 받침(종성) 후보로 보류
 *  - 종성이 채워진 상태에서 새 모음이 들어오면, 종성을 다음 음절의 초성으로 넘긴다
 *    (예: "가" + ㄴ(받침 후보) + ㅏ → 종성 ㄴ이 다음 음절로 넘어가 "가나")
 *
 * 지원 범위: 겹받침(ㄳ, ㄵ 등)과 이중모음(ㅘ, ㅝ, ㅢ 등)은 모델이 인식하지 않으므로
 * 이 클래스도 단일 자음/기본 모음만 처리한다. (config.py의 LABELS와 동일한 범위)
 */
public class HangulComposer {

    // 유니코드 한글 완성형 조합 공식에서 쓰는 표준 순서 (인덱스가 곧 초성/중성/종성 index)
    private static final char[] CHOSUNG = {
        'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
        'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    };
    private static final char[] JUNGSUNG = {
        'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ',
        'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ'
    };
    // 0번 인덱스는 "받침 없음"
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

    /** 확정된 자모 하나를 조합기에 투입한다. 자음/모음이 아닌 문자는 무시한다. */
    public synchronized void addJamo(char jamo) {
        if (CONSONANTS.contains(jamo)) {
            handleConsonant(jamo);
        } else if (VOWELS.contains(jamo)) {
            handleVowel(jamo);
        }
    }

    private void handleConsonant(char c) {
        if (cho == null) {
            cho = c; // 새 음절 시작
        } else if (jung == null) {
            // 초성만 있는 상태에서 자음이 또 옴 → 이전 초성은 낱자로 확정, 새 음절 시작
            flushOrphanChosung();
            cho = c;
        } else if (jong == null) {
            jong = c; // 받침 후보 (다음 입력에 따라 유지되거나 다음 음절로 넘어갈 수 있음)
        } else {
            // 초성+중성+종성 다 찬 상태 → 현재 음절 확정하고 새 음절 시작
            commitSyllable();
            cho = c;
        }
    }

    private void handleVowel(char v) {
        if (cho == null) {
            // 초성 없이 모음만 옴 → 낱자 모음으로 확정
            finalized.append(v);
        } else if (jung == null) {
            jung = v; // 중성 확정
        } else if (jong == null) {
            // 초성+중성만 있는데 모음이 또 옴 → 현재 음절 확정, 새 모음은 낱자로 붙임
            commitSyllable();
            finalized.append(v);
        } else {
            // 초성+중성+종성 다 찬 상태에서 모음이 옴 → 종성을 다음 음절의 초성으로 이동
            char movedJong = jong;
            jong = null;
            commitSyllable(); // 종성 없이 확정
            cho = movedJong;
            jung = v;
        }
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
                // 방어적 처리: 매핑 실패 시 원문 그대로 이어붙임
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

    /** 지금까지 확정된 텍스트 + 조합 중인 음절의 미리보기를 합쳐서 반환한다. */
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

    /** 조합 중이던 음절을 강제로 확정한다 (스페이스/완료 버튼 등에서 사용). */
    public synchronized void commitPending() {
        if (cho != null) {
            if (jung == null) flushOrphanChosung();
            else commitSyllable();
        }
    }

    /** 현재까지 조합 중인 걸 확정하고 띄어쓰기를 추가한다 (다음 단어 시작). */
    public synchronized void appendSpace() {
        commitPending();
        finalized.append(' ');
    }

    /** 전체 상태 초기화. */
    public synchronized void reset() {
        finalized.setLength(0);
        cho = null;
        jung = null;
        jong = null;
    }

    private static int indexOf(char[] arr, char c) {
        for (int i = 0; i < arr.length; i++) {
            if (arr[i] == c) return i;
        }
        return -1;
    }
}
