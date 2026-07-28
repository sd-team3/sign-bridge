package com.soldesk.service;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;

import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.JamoMapper;
import com.soldesk.mapper.SignWordMapper;
import com.soldesk.vo.JamoVO;
import com.soldesk.vo.SignWordVO;

@Service
public class LearnService {

    @Autowired
    private JamoMapper jamoMapper;

    @Autowired
    private SignWordMapper signWordMapper;

    public List<JamoVO> getConsonants() {
        return jamoMapper.findByType("CONSONANT");
    }

    public List<JamoVO> getVowels() {
        return jamoMapper.findByType("VOWEL");
    }

    public List<SignWordVO> getDictWords(String choseong, String keyword) {
        return signWordMapper.findList(choseong, keyword);
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

    public int countAll(){
        return jamoMapper.countAll();
    }
}