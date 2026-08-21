package com.soldesk.service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
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

@Service
public class ChainWordValidationService implements InitializingBean {

    private static final Logger log = LoggerFactory.getLogger(ChainWordValidationService.class);

    @Autowired
    private ChainWordMapper chainWordMapper;

    @Value("${krdict.api.key:}")
    private String krdictApiKey;

    @Value("${krdict.api.url:https://stdict.korean.go.kr/api/search.do}")
    private String krdictApiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final Map<String, Long> wordCache = new ConcurrentHashMap<>();

    @Override
    public void afterPropertiesSet() {
        try {
            for (ChainWordVO w : chainWordMapper.findAll()) {
                wordCache.put(w.getWordName(), w.getChainWordId());
            }
            log.info("chain_word 캐시 프리로드 완료: {}건", wordCache.size());
        } catch (Exception e) {
            log.warn("chain_word 캐시 프리로드 실패 (DB 조회 시점에 채워짐): {}", e.getMessage());
        }
    }

    private static final Pattern HANGUL_WORD = Pattern.compile("^[가-힣]{2,10}$");

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

        Long cachedId = wordCache.get(word);
        if (cachedId != null) {
            return ChainWordValidationResult.valid(cachedId);
        }

        ChainWordVO cached = chainWordMapper.findByName(word);
        if (cached != null) {
            wordCache.put(word, cached.getChainWordId());
            return ChainWordValidationResult.valid(cached.getChainWordId());
        }

        if (!checkExternalDictionary(word)) {
            return ChainWordValidationResult.invalid(ChainWordLogVO.REASON_NOT_FOUND);
        }

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
        if (chainWordId != null) wordCache.put(word, chainWordId);
        return ChainWordValidationResult.valid(chainWordId);
    }

    private boolean matchesRequiredChar(String word, String requiredFirstChar) {
        char first = word.charAt(0);
        char required = requiredFirstChar.charAt(0);
        if (first == required) return true;
        Character alt = DueumRuleUtil.alternativeInitial(required);
        return alt != null && first == alt;
    }

    public String alternativeFirstChar(String requiredFirstChar) {
        if (requiredFirstChar == null || requiredFirstChar.isEmpty()) return null;
        Character alt = DueumRuleUtil.alternativeInitial(requiredFirstChar.charAt(0));
        return alt == null ? null : String.valueOf(alt);
    }

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
            if (total <= 0) {
                log.debug("krdict 검색 결과 0건 (단어: {}) 응답: {}", word, body);
                return false;
            }

            JsonNode itemsNode = channel.path("item");
            java.util.List<JsonNode> items = new java.util.ArrayList<>();
            if (itemsNode.isArray()) {
                itemsNode.forEach(items::add);
            } else if (itemsNode.isObject()) {
                items.add(itemsNode);
            }

            for (JsonNode item : items) {
                String pos = extractPos(item);
                String itemWord = item.path("word").asText("").replaceAll("[^가-힣]", "");
                if (itemWord.equals(word) && pos.contains("명사")) {
                    return true;
                }
            }
            log.info("krdict 응답에 단어는 있으나 조건(명사) 불일치로 거부됨 (단어: {}) 응답: {}", word, body);
            return false;
        } catch (Exception e) {
            log.error("국립국어원 API 조회 실패 (단어: {}): {}", word, e.getMessage());
            return false;
        }
    }

    private String extractPos(JsonNode item) {
        String direct = item.path("pos").asText("");
        if (!direct.isBlank()) return direct;

        JsonNode sense = item.path("sense");
        if (sense.isArray()) {
            for (JsonNode s : sense) {
                String p = s.path("pos").asText("");
                if (!p.isBlank()) return p;
            }
            return "";
        }
        return sense.path("pos").asText("");
    }
}
