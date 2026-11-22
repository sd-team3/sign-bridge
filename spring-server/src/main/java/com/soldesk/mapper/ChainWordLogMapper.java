package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.ChainWordLogVO;

public interface ChainWordLogMapper {

    void insertLog(ChainWordLogVO log);


    List<ChainWordLogVO> findLogsByRoom(@Param("chainRoomId") Long chainRoomId);

    void deleteLogsByRoomIds(@Param("roomIds") java.util.List<Long> roomIds);
}
