package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.ChainWordLogVO;

public interface ChainWordLogMapper {

    void insertLog(ChainWordLogVO log);

    /** 특정 방의 전체 단어 진행 로그 (턴 순서대로) - 게임 화면 실시간 로그 + 종료 후 전적 상세에 그대로 사용 */
    List<ChainWordLogVO> findLogsByRoom(@Param("chainRoomId") Long chainRoomId);

    void deleteLogsByRoomIds(@Param("roomIds") java.util.List<Long> roomIds);
}
