package com.soldesk.mapper;

import java.util.List;

import com.soldesk.vo.NotificationVO;

public interface NotificationMapper {

    void notifyUser(NotificationVO vo);

    List<NotificationVO> notiList(int memberId);

    void isRead(int notificationId);

}