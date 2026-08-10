package com.soldesk.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Param;
import com.soldesk.vo.FavoriteWordVO;

public interface FavoriteMapper {
    int existsFavorite(@Param("memberId") Integer memberId, @Param("signWordId") Integer signWordId);
    int insertFavorite(@Param("memberId") Integer memberId, @Param("signWordId") Integer signWordId);
    int deleteFavorite(@Param("memberId") Integer memberId, @Param("signWordId") Integer signWordId);
    List<FavoriteWordVO> findFavoritesByMember(@Param("memberId") Integer memberId,
                                                @Param("offset") int offset,
                                                @Param("limit") int limit);
    int countFavoritesByMember(Integer memberId);
    List<Integer> findFavoriteIdsByMember(Integer memberId);
}