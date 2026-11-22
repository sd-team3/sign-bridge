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





    private volatile List<SignWordVO> allWordsCache = null;

    public List<JamoVO> getConsonants() {
        return jamoMapper.findByType("CONSONANT");
    }

    public List<JamoVO> getVowels() {
        return jamoMapper.findByType("VOWEL");
    }

    public List<SignWordVO> getDictWords(String choseong, String keyword) {

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


    public List<SignWordVO> getWordList(String keyword, int offset, int pageSize) {
        return signWordMapper.getWordList(keyword, offset, pageSize);
    }


    public int getWordCount(String keyword) {
        return signWordMapper.getCount(keyword);
    }


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
        clearWordCache();
    }

    public int countAll() {
        return jamoMapper.countAll();
    }



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