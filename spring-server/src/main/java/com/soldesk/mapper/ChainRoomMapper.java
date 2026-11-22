package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.ChainRoomMemberVO;
import com.soldesk.vo.ChainRoomVO;

public interface ChainRoomMapper {



    Long insertRoom(ChainRoomVO room);

    ChainRoomVO findRoomById(@Param("chainRoomId") Long chainRoomId);


    List<ChainRoomVO> findWaitingRooms();

    void updateRoomStatus(@Param("chainRoomId") Long chainRoomId, @Param("status") String status);

    void updateHost(@Param("chainRoomId") Long chainRoomId, @Param("hostMemberId") Integer hostMemberId);


    void startRoom(@Param("chainRoomId") Long chainRoomId,
                    @Param("currentTurnMemberId") Integer currentTurnMemberId,
                    @Param("currentTurnDeadline") java.time.LocalDateTime currentTurnDeadline);


    void advanceTurn(@Param("chainRoomId") Long chainRoomId,
                      @Param("currentTurnMemberId") Integer currentTurnMemberId,
                      @Param("currentTurnDeadline") java.time.LocalDateTime currentTurnDeadline,
                      @Param("lastChainWordId") Long lastChainWordId);


    void endRoom(@Param("chainRoomId") Long chainRoomId,
                 @Param("winnerMemberId") Integer winnerMemberId);

    void deleteRoom(@Param("chainRoomId") Long chainRoomId);



    void insertRoomMember(ChainRoomMemberVO member);

    void deleteRoomMember(@Param("chainRoomId") Long chainRoomId, @Param("memberId") Integer memberId);

    int countRoomMembers(@Param("chainRoomId") Long chainRoomId);


    List<ChainRoomMemberVO> findMembersByRoom(@Param("chainRoomId") Long chainRoomId);

    ChainRoomMemberVO findRoomMember(@Param("chainRoomId") Long chainRoomId, @Param("memberId") Integer memberId);

    Integer findMaxTurnNo(@Param("chainRoomId") Long chainRoomId);

    void updateLivesAndScore(@Param("chainRoomId") Long chainRoomId,
                              @Param("memberId") Integer memberId,
                              @Param("lives") Integer lives,
                              @Param("scoreDelta") Integer scoreDelta);

    void eliminateMember(@Param("chainRoomId") Long chainRoomId,
                          @Param("memberId") Integer memberId,
                          @Param("eliminatedDate") java.time.LocalDateTime eliminatedDate);

    void setFinalRank(@Param("chainRoomId") Long chainRoomId,
                       @Param("memberId") Integer memberId,
                       @Param("finalRank") Integer finalRank);




    List<ChainRoomVO> findEndedRoomsByMember(@Param("memberId") Integer memberId,
                                              @Param("offset") int offset,
                                              @Param("pageSize") int pageSize);

    int countEndedRoomsByMember(@Param("memberId") Integer memberId);


    boolean isRoomParticipant(@Param("chainRoomId") Long chainRoomId, @Param("memberId") Integer memberId);



    List<Long> findRoomIdsByStatus(@Param("status") String status);

    void deleteMembersByRoomIds(@Param("roomIds") List<Long> roomIds);

    void deleteRoomsByStatus(@Param("status") String status);
}
