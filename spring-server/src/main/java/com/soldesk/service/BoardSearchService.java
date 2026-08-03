package com.soldesk.service;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.soldesk.mapper.BoardMapper;
import com.soldesk.vo.BoardDocument;
import com.soldesk.vo.BoardVO;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.elasticsearch.core.search.Hit;
import co.elastic.clients.elasticsearch.indices.ExistsRequest;
import co.elastic.clients.elasticsearch.indices.CreateIndexRequest;
import co.elastic.clients.elasticsearch._types.SortOrder;
import co.elastic.clients.elasticsearch._types.query_dsl.TextQueryType;
import co.elastic.clients.elasticsearch.core.CountResponse;

@Service
public class BoardSearchService implements InitializingBean {
    @Autowired
    private ElasticsearchClient elasticsearchClient;
    @Autowired
    private BoardMapper boardMapper;
    @Value("${elasticsearch.index}")
    private String indexName;

    public void createIndex() throws Exception {
        try {
            boolean exists = elasticsearchClient.indices()
                .exists(ExistsRequest.of(req -> req.index(indexName))).value();
            if(!exists) {
                elasticsearchClient.indices()
                    .create(CreateIndexRequest.of(create -> create.index(indexName)
                    .settings(settings -> settings
                        .analysis(analysis -> analysis
                            .analyzer("nori_analyzer", analyzer -> analyzer
                                .custom(custom -> custom
                                    .tokenizer("nori_tokenizer")
                                )
                            )
                        )
                    )
                    .mappings(mappings -> mappings
                        .properties("boardId", p->p.integer(i->i))
                        .properties("memberId", p->p.integer(i->i))
                        .properties("memberName", p->p.keyword(i->i))
                        .properties("boardTitle", p->p.text(t->t.analyzer("nori_analyzer")))
                        .properties("boardContent", p->p.text(t->t.analyzer("nori_analyzer")))
                        .properties("categoryIdx", p->p.keyword(i->i))
                        .properties("viewCount", p->p.integer(i->i))
                        .properties("noticeYn", p->p.keyword(i->i))
                        .properties("regDate", p->p.date(i->i))
                        .properties("modDate", p->p.date(i->i))
                    )));
            }
        } catch (Exception e) {
            throw e;
        }

    }

    @Override
    public void afterPropertiesSet() throws Exception {
        try {
            createIndex();
            List<BoardVO> boards = boardMapper.findAllForIndex();
            for(BoardVO board: boards) {
                elasticsearchClient.index(index -> index
                    .index(indexName)
                    .id(String.valueOf(board.getBoardId()))
                    .document(BoardDocument.from(board))
                );
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
    }
    
    public void indexBoard(BoardVO board) {
        try {
            elasticsearchClient.index(index -> index
                .index(indexName)
                .id(String.valueOf(board.getBoardId()))
                .document(BoardDocument.from(board))
            );
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void deleteBoard(int boardId) {
        try {
            elasticsearchClient.delete(delete -> delete
                .index(indexName)
                .id(String.valueOf(boardId))
            );
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public List<BoardVO> search(String keyword, int page) throws IOException {
        int count = 6;
        int start = (page - 1) * count;
        try {
            SearchResponse<BoardDocument> response = elasticsearchClient.search(search -> search
                .index(indexName)
                .from(start)
                .size(count)
                .sort(sort -> sort.field(field -> field.field("regDate").order(SortOrder.Desc)))
                .query(query -> query.bool(bool -> 
                    bool.must(must -> must.multiMatch(multi -> multi
                        .fields("boardTitle", "boardContent")
                        .query(keyword)
                        .type(TextQueryType.MostFields)))
                )), BoardDocument.class);
                List<BoardVO> boards = new ArrayList<BoardVO>();
                for(Hit<BoardDocument> hit: response.hits().hits()) {
                    BoardDocument document = hit.source();
                    if(document != null) boards.add(document.toBoardVO());
                }
                return boards;
            }
            catch (Exception e) {
                e.printStackTrace();
                return new ArrayList<>();
            }
            
        } 

    public long searchCount(String keyword) throws IOException {
        try {
            CountResponse response = elasticsearchClient.count(count -> count
                .index(indexName)
                .query(query -> query.bool(bool -> 
                    bool.must(must -> must.multiMatch(multi -> multi
                        .fields("boardTitle", "boardContent")
                        .query(keyword)
                        .type(TextQueryType.MostFields)))
                ))
            );
            return response.count();
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }

    }
}
