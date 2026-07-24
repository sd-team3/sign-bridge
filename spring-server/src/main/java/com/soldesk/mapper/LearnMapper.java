package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.JamoVO;

public interface LearnMapper {
    
    List<JamoVO> findByType(@Param("jamoType") String jamoType);    
}
