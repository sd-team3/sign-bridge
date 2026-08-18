package com.soldesk.service;

import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.soldesk.dto.ChainWordValidationResult;
import com.soldesk.mapper.ChainWordMapper;
import com.soldesk.util.DueumRuleUtil;
import com.soldesk.vo.ChainWordLogVO;
import com.soldesk.vo.ChainWordVO;

/**
 * 끝말잇기 단어 검증.
 *  1. chain_word 테이블(이미 검증된 단어집)에 있는지 우선 확인
 *  2. 없으면 국립국어원 표준국어대사전 Open API 로 실제 존재하는 "명사"인지 조회
 *     - ~하다/~되다/~이다 등 범용 어미로 끝나는(용언화된) 항목은 제외
 *  3. API로 새로 검증된 단어는 chain_word 에 캐시 적재해서 다음부터는 DB만으로 판정
 */
@Service
public class ChainWordValidationService {

    private static final Logger log = LoggerFactory.getLogger(ChainWordValidationService.class);

    @Autowired
    private ChainWordMapper chainWordMapper;

    @Value("${krdict.api.key:}")
    private String krdictApiKey;

    @Value("${krdict.api.url:https://stdict.korean.go.kr/api/search.do}")
    private String krdictApiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 순우리말 음절 2~10자, 완성형 한글만 허용
    private static final Pattern HANGUL_WORD = Pattern.compile("^[가-힣]{2,10}$");

    // ~하다/~되다/~이다 류의 범용 어미로 끝나 "단어 자체"라기보다 서술어로 판단되는 경우 제외
    // (리모컨/사과처럼 그 자체로 명사인 단어만 유효)
    private static final Pattern GENERIC_SUFFIX = Pattern.compile(
        "(하다|되다|이다|스럽다|답다|같다|거리다|대다|당하다|시키다|화하다|적이다|하기|하며|해서|임|함)$"
    );

    public ChainWordValidationResult validate(String rawWord, String requiredFirstChar) {
        String word = rawWord == null ? "" : rawWord.trim();

        if (!HANGUL_WORD.matcher(word).matches()) {
            return ChainWordValidationResult.invalid(ChainWordLogVO.REASON_NOT_FOUND);
        }
        if (GENERIC_SUFFIX.matcher(word).find()) {
            return ChainWordValidationResult.invalid(ChainWordLogVO.REASON_INVALID_FORM);
        }
        if (requiredFirstChar != null && !requiredFirstChar.isEmpty() && !matchesRequiredChar(word, requiredFirstChar)) {
            return ChainWordValidationResult.invalid(ChainWordLogVO.REASON_WRONG_START_CHAR);
        }

        // 1) DB 캐시(chain_word) 우선 확인
        ChainWordVO cached = chainWordMapper.findByName(word);
        if (cached != null) {
            return ChainWordValidationResult.valid(cached.getChainWordId());
        }

        // 2) 국립국어원 Open API 로 실제 단어인지 확인
        if (!checkExternalDictionary(word)) {
            return ChainWordValidationResult.invalid(ChainWordLogVO.REASON_NOT_FOUND);
        }

        // 3) 신규 검증 단어 캐시 적재
        ChainWordVO newWord = new ChainWordVO();
        newWord.setWordName(word);
        newWord.setFirstChar(word.substring(0, 1));
        newWord.setLastChar(word.substring(word.length() - 1));
        try {
            chainWordMapper.insertIgnore(newWord);
        } catch (Exception e) {
            log.warn("chain_word insert 실패(동시 삽입 등으로 무시 가능): {}", e.getMessage());
        }
        ChainWordVO saved = chainWordMapper.findByName(word);
        Long chainWordId = saved != null ? saved.getChainWordId() : null;
        return ChainWordValidationResult.valid(chainWordId);
    }

    /** 앞말의 끝 글자(requiredFirstChar) 또는 그 두음법칙 변환형으로 시작하면 인정 */
    private boolean matchesRequiredChar(String word, String requiredFirstChar) {
        char first = word.charAt(0);
        char required = requiredFirstChar.charAt(0);
        if (first == required) return true;
        Character alt = DueumRuleUtil.alternativeInitial(required);
        return alt != null && first == alt;
    }

    /** 화면에 "다음 글자는 O(또는 O)" 형태로 안내하기 위한 대체 시작글자. 없으면 null. */
    public String alternativeFirstChar(String requiredFirstChar) {
        if (requiredFirstChar == null || requiredFirstChar.isEmpty()) return null;
        Character alt = DueumRuleUtil.alternativeInitial(requiredFirstChar.charAt(0));
        return alt == null ? null : String.valueOf(alt);
    }

    /** 국립국어원 표준국어대사전 Open API로 명사 여부까지 확인. 키 미설정/오류 시 false(=미확인 단어는 거부). */
    private boolean checkExternalDictionary(String word) {
        if (krdictApiKey == null || krdictApiKey.isBlank() || krdictApiKey.startsWith("REPLACE_WITH")) {
            log.warn("krdict.api.key 가 설정되지 않아 외부 사전 검증을 건너뜁니다. (단어: {})", word);
            return false;
        }
        try {
            String url = UriComponentsBuilder.fromHttpUrl(krdictApiUrl)
                .queryParam("key", krdictApiKey)
                .queryParam("q", word)
                .queryParam("req_type", "json")
                .queryParam("part", "word")
                .queryParam("method", "exact")
                .toUriString();

            String body = restTemplate.getForObject(url, String.class);
            if (body == null) return false;

            JsonNode root = objectMapper.readTree(body);
            JsonNode channel = root.path("channel");
            int total = channel.path("total").asInt(0);
            if (total <= 0) return false;

            JsonNode items = channel.path("item");
            for (JsonNode item : items) {
                String pos = item.path("sense").path("pos").asText("");
                String itemWord = item.path("word").asText("").replaceAll("[^가-힣]", "");
                if (itemWord.equals(word) && pos.contains("명사")) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            log.error("국립국어원 API 조회 실패 (단어: {}): {}", word, e.getMessage());
            return false;
        }
    }
}
