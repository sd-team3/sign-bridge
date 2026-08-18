package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.ChainRoomMemberVO;
import com.soldesk.vo.ChainRoomVO;

public interface ChainRoomMapper {

    // ---- chain_room ----

    Long insertRoom(ChainRoomVO room); // insert 후 chainRoomId 가 파라미터 객체에 채워짐 (useGeneratedKeys)

    ChainRoomVO findRoomById(@Param("chainRoomId") Long chainRoomId);

    /** 로비 목록: WAITING 상태 방만, 최신순 */
    List<ChainRoomVO> findWaitingRooms();

    void updateRoomStatus(@Param("chainRoomId") Long chainRoomId, @Param("status") String status);

    void updateHost(@Param("chainRoomId") Long chainRoomId, @Param("hostMemberId") Integer hostMemberId);

    /** 게임 시작 처리: status=PLAYING, started_date=now, 첫 턴 정보 세팅 */
    void startRoom(@Param("chainRoomId") Long chainRoomId,
                    @Param("currentTurnMemberId") Integer currentTurnMemberId,
                    @Param("currentTurnDeadline") java.time.LocalDateTime currentTurnDeadline);

    /** 턴 진행: 다음 턴 플레이어/마감시각/마지막 성공단어 갱신 */
    void advanceTurn(@Param("chainRoomId") Long chainRoomId,
                      @Param("currentTurnMemberId") Integer currentTurnMemberId,
                      @Param("currentTurnDeadline") java.time.LocalDateTime currentTurnDeadline,
                      @Param("lastChainWordId") Long lastChainWordId);

    /** 게임 종료 처리 */
    void endRoom(@Param("chainRoomId") Long chainRoomId,
                 @Param("winnerMemberId") Integer winnerMemberId);

    void deleteRoom(@Param("chainRoomId") Long chainRoomId);

    // ---- chain_room_member ----

    void insertRoomMember(ChainRoomMemberVO member);

    void deleteRoomMember(@Param("chainRoomId") Long chainRoomId, @Param("memberId") Integer memberId);

    int countRoomMembers(@Param("chainRoomId") Long chainRoomId);

    /** member 테이블 join 해서 이름/프로필까지 채워서 turn_no 순으로 반환 */
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

    // ---- 마이페이지 "내 전적" ----

    /** 내가 참여했고 종료된(ENDED) 방 목록 (최신순, 페이징) */
    List<ChainRoomVO> findEndedRoomsByMember(@Param("memberId") Integer memberId,
                                              @Param("offset") int offset,
                                              @Param("pageSize") int pageSize);

    int countEndedRoomsByMember(@Param("memberId") Integer memberId);

    /** 참가자만 열람 가능하도록 접근권한 체크용 */
    boolean isRoomParticipant(@Param("chainRoomId") Long chainRoomId, @Param("memberId") Integer memberId);

    // ---- 서버 재시작 시 진행 중이던 방 정리 ----

    List<Long> findRoomIdsByStatus(@Param("status") String status);

    void deleteMembersByRoomIds(@Param("roomIds") List<Long> roomIds);

    void deleteRoomsByStatus(@Param("status") String status);
}
