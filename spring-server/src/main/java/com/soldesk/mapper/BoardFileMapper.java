package com.soldesk.mapper;

import java.util.List;
import com.soldesk.vo.BoardFileVO;

public interface BoardFileMapper {
    void insertBoardFile(BoardFileVO file);
    List<BoardFileVO> selectFilesByBoardId(int boardId);
    BoardFileVO selectFileById(long boardFileId);
    void deleteBoardFileById(long boardFileId); 
}
