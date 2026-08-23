package com.soldesk.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.FavoriteMapper;
import com.soldesk.vo.FavoriteWordVO;

@Service
public class FavoriteService {

    @Autowired
    private FavoriteMapper favoriteMapper;

    // 단어 즐겨찾기 처리
    // true = 즐겨찾기 추가됨, false = 해제됨
    public boolean toggleFavorite(Integer memberId, Integer signWordId) {
        boolean exists = favoriteMapper.existsFavorite(memberId, signWordId) > 0;
        if (exists) {
            favoriteMapper.deleteFavorite(memberId, signWordId);
            return false;
        } else {
            favoriteMapper.insertFavorite(memberId, signWordId);
            return true;
        }
    }

    // 즐겨찾기한 단어 조회
    public List<FavoriteWordVO> getFavorites(Integer memberId, int page, int pageSize) {
        int offset = (page - 1) * pageSize;
        return favoriteMapper.findFavoritesByMember(memberId, offset, pageSize);
    }

    // 즐겨찾기한 단어 카운트
    public int countFavorites(Integer memberId) {
        return favoriteMapper.countFavoritesByMember(memberId);
    }

    // 멤버 id 기준 즐겨찾기한 단어 조회
    public List<Integer> getFavoriteIds(Integer memberId) {
        return favoriteMapper.findFavoriteIdsByMember(memberId);
    }
}
