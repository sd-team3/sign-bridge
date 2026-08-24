package com.soldesk.service;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.JamoMapper;
import com.soldesk.mapper.RecognitionConfirmLogMapper;
import com.soldesk.mapper.SignWordMapper;
import com.soldesk.vo.JamoVO;
import com.soldesk.vo.SignWordVO;

@Service
public class LearnService {

    @Autowired
    private JamoMapper jamoMapper;

    @Autowired
    private SignWordMapper signWordMapper;

    @Autowired
    private RecognitionConfirmLogMapper recognitionConfirmLogMapper;

    // 사전 전체 목록(필터 없는 경우) 캐시.
    // 페이지 이동할 때마다 3696건을 매번 새로 긁어오면 너무 느려서
    // 서버 메모리에 한 번만 담아두고 재사용.
    // 어드민이 단어 수정하면 clearWordCache()로 비움.
    private volatile List<SignWordVO> allWordsCache = null;

    public List<JamoVO> getConsonants() {
        return jamoMapper.findByType("CONSONANT");
    }

    public List<JamoVO> getVowels() {
        return jamoMapper.findByType("VOWEL");
    }

    public List<SignWordVO> getDictWords(String choseong, String keyword) {
        // 필터 없는 전체 조회일 때만 캐시 사용 (choseong/keyword 검색은 그대로 DB 조회)
        boolean noFilter = (choseong == null || choseong.isBlank())
                && (keyword == null || keyword.isBlank());

        if (noFilter) {
            if (allWordsCache == null) {
                synchronized (this) {
                    if (allWordsCache == null) {
                        allWordsCache = signWordMapper.findList(null, null);
                    }
                }
            }
            return allWordsCache;
        }

        return signWordMapper.findList(choseong, keyword);
    }

    // 캐시 비우기 - 어드민이 단어 수정했을 때 호출해서 다음 조회 때 최신 데이터로 다시 채워지게 함
    public void clearWordCache() {
        allWordsCache = null;
    }

    public SignWordVO getDictWordDetail(String signWordName) {
        return signWordMapper.findByName(signWordName);
    }

    public void increaseViewCount(String signWordName) {
        signWordMapper.incrementViewCount(signWordName);
    }

    public SignWordVO getRandomDictWord() {
        return signWordMapper.findRandom();
    }

    // 국립수어사전 원본 영상은 Referer 헤더 체크로 핫링크를 막고 있어
    // 서버가 대신 요청해서 (정상적인 Referer를 붙여서) 스트림만 그대로 전달한다
    public void proxyVideo(String videoUrl, HttpServletResponse response) throws IOException {
        URL url = new URL(videoUrl);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestProperty("Referer", "http://sldict.korean.go.kr/");
        conn.setRequestProperty("User-Agent", "Mozilla/5.0");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(10000);

        int status = conn.getResponseCode();
        if (status != HttpURLConnection.HTTP_OK && status != HttpURLConnection.HTTP_PARTIAL) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        response.setContentType(conn.getContentType());
        String contentLength = conn.getHeaderField("Content-Length");
        if (contentLength != null) {
            response.setHeader("Content-Length", contentLength);
        }

        try (InputStream in = conn.getInputStream();
                OutputStream out = response.getOutputStream()) {
            in.transferTo(out);
        }
    }

    // 어드민 간단한 단어 리스트 (페이징)
    public List<SignWordVO> getWordList(String keyword, int offset, int pageSize) {
        return signWordMapper.getWordList(keyword, offset, pageSize);
    }

    // 단어 개수
    public int getWordCount(String keyword) {
        return signWordMapper.getCount(keyword);
    }

    // 아이디로 단어 이름 가져오기
    public SignWordVO getDictWordDetailById(int signWordId) {
        return signWordMapper.getDictWordDetailById(signWordId);
    }

    public void updateWord(int signWordId,
            String signWordName,
            String choseong,
            String signWordVideo,
            String signWordThumbnail,
            String description) {
        signWordMapper.updateWord(signWordId, signWordName, choseong, signWordVideo, signWordThumbnail, description);
        clearWordCache(); // 어드민이 단어 수정했으니 캐시된 목록도 최신화 필요
    }

    public int countAll() {
        return jamoMapper.countAll();
    }

    // 학습 메인페이지 "나의 학습 기록" 카드에 쓸 "최근 학습: N" 라벨.
    // 학습 기록이 없으면 null 반환 -> jsp에서 문구를 다르게 보여줌.
    public String getLastLearningLabel(int memberId) {
        LocalDateTime lastRegDate = recognitionConfirmLogMapper.findLastRegDateByMemberId((long) memberId);
        if (lastRegDate == null) {
            return null;
        }

        long daysBetween = ChronoUnit.DAYS.between(lastRegDate.toLocalDate(), LocalDate.now());
        if (daysBetween <= 0) {
            return "오늘";
        } else if (daysBetween == 1) {
            return "어제";
        } else {
            return daysBetween + "일 전";
        }
    }
}