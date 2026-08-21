package com.soldesk.util;

public final class DueumRuleUtil {

    private DueumRuleUtil() {}

    private static final int BASE = 0xAC00;
    private static final int CHO_COUNT = 19;
    private static final int JUNG_COUNT = 21;
    private static final int JONG_COUNT = 28;

    private static final int CHO_NIEUN = 2;  // ㄴ
    private static final int CHO_RIEUL = 5;  // ㄹ
    private static final int CHO_IEUNG = 11; // ㅇ

    private static final boolean[] PALATAL = new boolean[JUNG_COUNT];
    static {
        int[] idx = {2, 3, 6, 7, 12, 17, 20};
        for (int i : idx) PALATAL[i] = true;
    }

    public static Character alternativeInitial(char c) {
        if (c < BASE || c > BASE + 11171) return null;
        int offset = c - BASE;
        int cho = offset / (JUNG_COUNT * JONG_COUNT);
        int jung = (offset % (JUNG_COUNT * JONG_COUNT)) / JONG_COUNT;
        int jong = offset % JONG_COUNT;

        Integer newCho = null;
        if (cho == CHO_RIEUL) {
            newCho = PALATAL[jung] ? CHO_IEUNG : CHO_NIEUN;
        } else if (cho == CHO_NIEUN) {
            if (PALATAL[jung]) newCho = CHO_IEUNG;
        }
        if (newCho == null) return null;

        int newOffset = (newCho * JUNG_COUNT + jung) * JONG_COUNT + jong;
        return (char) (BASE + newOffset);
    }
}
