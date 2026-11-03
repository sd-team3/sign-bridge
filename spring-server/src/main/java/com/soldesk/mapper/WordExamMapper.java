package com.soldesk.mapper;

import java.util.List;
import org.apache.ibatis.annotations.*;

public interface WordExamMapper {
    @Insert("INSERT INTO word_exam(exam_id, member_id, payload) VALUES(#{id}, #{member}, #{payload})")
    void insert(@Param("id") String id, @Param("member") int member, @Param("payload") String payload);

    @Select("SELECT payload FROM word_exam WHERE exam_id=#{id} AND member_id=#{member}")
    String find(@Param("id") String id, @Param("member") int member);

    @Select("SELECT payload FROM word_exam WHERE exam_id=#{id} AND member_id=#{member} FOR UPDATE")
    String lock(@Param("id") String id, @Param("member") int member);

    @Update("UPDATE word_exam SET payload=#{payload} WHERE exam_id=#{id} AND member_id=#{member}")
    void update(@Param("id") String id, @Param("member") int member, @Param("payload") String payload);

    @Select("SELECT payload FROM word_exam WHERE member_id=#{member} ORDER BY started_at DESC, exam_id DESC LIMIT 20")
    List<String> history(@Param("member") int member);
}
