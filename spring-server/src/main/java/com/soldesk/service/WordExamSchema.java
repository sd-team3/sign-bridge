package com.soldesk.service;

import javax.sql.DataSource;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.stereotype.Component;

@Component("wordExamSchema")
public class WordExamSchema implements InitializingBean {
    private final DataSource dataSource;
    private final boolean initialize;

    public WordExamSchema(DataSource dataSource, @Value("${word.exam.initialize-schema:true}") boolean initialize) {
        this.dataSource = dataSource;
        this.initialize = initialize;
    }

    @Override
    public void afterPropertiesSet() {
        if (initialize) new ResourceDatabasePopulator(new ClassPathResource("db/word-exam.sql")).execute(dataSource);
    }
}
