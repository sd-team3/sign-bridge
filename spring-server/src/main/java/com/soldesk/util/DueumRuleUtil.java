package com.soldesk.util;

/**
 * 두음법칙: 단어 첫머리에서 'ㄹ'은 'ㅣ,야,여,예,요,유' 앞에서 'ㅇ'으로, 그 외 모음 앞에서 'ㄴ'으로 적고,
 * 'ㄴ'은 'ㅣ,야,여,예,요,유' 앞에서 'ㅇ'으로 적는다. (한글 맞춤법 제3장 제5절)
 * 끝말잇기에서 앞말의 끝 글자로 시작하는 단어가 실제로는 두음법칙 변환형으로만 존재하는 경우
 * (예: 력사→역사, 로인→노인) 그 변환형도 첫 글자로 인정하기 위해 사용한다.
 */
public final class DueumRuleUtil {

    private DueumRuleUtil() {}

    private static final int BASE = 0xAC00;
    private static final int CHO_COUNT = 19;
    private static final int JUNG_COUNT = 21;
    private static final int JONG_COUNT = 28;

    private static final int CHO_NIEUN = 2;  // ㄴ
    private static final int CHO_RIEUL = 5;  // ㄹ
    private static final int CHO_IEUNG = 11; // ㅇ

    // ㅑㅒㅕㅖㅛㅠㅣ 앞 (야계열 + ㅣ)
    private static final boolean[] PALATAL = new boolean[JUNG_COUNT];
    static {
        int[] idx = {2, 3, 6, 7, 12, 17, 20};
        for (int i : idx) PALATAL[i] = true;
    }

    /** 주어진 글자가 두음법칙 적용 대상이면 변환된 글자를, 아니면 null 을 반환 */
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
