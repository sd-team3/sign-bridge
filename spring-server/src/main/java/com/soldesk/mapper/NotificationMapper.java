package com.soldesk.mapper;

import org.apache.ibatis.annotations.Param;

public interface NotificationMapper {

    void notifyUser(@Param("userId") int userId, 
                     @Param("title") String title, 
                     @Param("content") String content);

}