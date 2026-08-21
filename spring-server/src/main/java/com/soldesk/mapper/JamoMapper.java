package com.soldesk.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.soldesk.vo.JamoVO;

public interface JamoMapper {
    
    List<JamoVO> findByType(@Param("jamoType") String jamoType); 
    JamoVO findByChar(@Param("jamoChar") String jamoChar);
    
    int countAll();
}
