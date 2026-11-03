import java.nio.file.*;
import java.util.*;
import java.io.*;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.multipart.MultipartFile;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.node.*;
import com.soldesk.mapper.WordExamMapper;
import com.soldesk.service.*;
import com.soldesk.service.SignLearningApiService.ApiException;

public class WordExamSmoke {
    static final ObjectMapper JSON = new ObjectMapper();
    static int checks;
    static void check(boolean condition, String message) { checks++; if (!condition) throw new AssertionError(message); }
    static void rejects(int status, Runnable action) {
        try { action.run(); throw new AssertionError("Expected " + status); }
        catch (ApiException error) { check(error.getStatus() == status, error.getMessage()); }
    }
    static class Learning extends SignLearningApiService {
        int calls;
        JsonNode result;
        Learning() { super("http://localhost:1", "", 100, 100); }
        @Override public JsonNode chapters(String context) {
            ObjectNode n = JSON.createObjectNode().put("total_words",70).put("curriculum_version","basic70-test");
            ArrayNode chapters = n.putArray("chapters");
            for (int c=1;c<=7;c++) chapters.addObject().put("chapter_id",String.format("chapter-%02d",c)).put("title","챕터 "+c);
            return n;
        }
        @Override public JsonNode chapter(String id, String context) {
            int c=Integer.parseInt(id.substring(8)); ObjectNode n=JSON.createObjectNode(); ArrayNode words=n.putArray("words");
            for(int i=0;i<10;i++) { int k=(c-1)*10+i; words.addObject().put("word_id",String.format("WORD%04d",k)).put("label","단어"+k).put("chapter_id",id); }
            return n;
        }
        @Override public JsonNode evaluate(String word, String attempt, MultipartFile video) { calls++; return result.deepCopy(); }
    }
    static ObjectNode evaluation(boolean matches,double score,String reason) {
        ObjectNode n=JSON.createObjectNode().put("status","ok").put("model_id","test-model");
        ObjectNode r=n.putObject("recognition").put("target_matches_top1",matches);
        r.putArray("top3").addObject().put("score",score);
        n.putObject("feedback").put("reason",reason).put("feedback_required",true).putObject("similarity").put("score",40);
        return n;
    }
    public static void main(String[] args) throws Exception {
        DriverManagerDataSource ds=new DriverManagerDataSource("jdbc:h2:mem:exam;MODE=MySQL;DB_CLOSE_DELAY=-1","sa","");
        new WordExamSchema(ds, true).afterPropertiesSet();
        new WordExamSchema(ds, true).afterPropertiesSet();
        SqlSessionFactoryBean factory=new SqlSessionFactoryBean(); factory.setDataSource(ds); factory.afterPropertiesSet();
        factory.getObject().getConfiguration().addMapper(WordExamMapper.class);
        SqlSessionTemplate sessions=new SqlSessionTemplate(factory.getObject()); WordExamMapper mapper=sessions.getMapper(WordExamMapper.class);
        Learning learning=new Learning(); WordExamService service=new WordExamService(mapper,learning,new DataSourceTransactionManager(ds));
        JsonNode exam=service.start(10,"both","chapter-01",""); String id=exam.path("id").asText();
        check(exam.path("questions").size()==10,"chapter count");
        for(JsonNode q:exam.path("questions")) if(q.path("type").asText().equals("choice")) check(!q.has("word_id")&&!q.has("label")&&!q.has("evaluation"),"no answer disclosure");
        check(service.get(id,10).equals(exam),"resume persisted state");
        rejects(404,()->service.get(id,11)); rejects(404,()->service.finish(id,11));
        rejects(409,()->service.choice(id,10,2,"WORD0000")); rejects(422,()->service.choice(id,10,0,"WORD9999"));
        JsonNode internal=JSON.readTree(mapper.find(id,10)); String answer=internal.path("questions").get(0).path("word_id").asText();
        service.choice(id,10,0,answer); String saved=mapper.find(id,10); service.choice(id,10,0,"WORD9999");
        check(saved.equals(mapper.find(id,10)),"duplicate choice cannot rewrite answer");
        rejects(409,()->service.referenceWord(id,10,1));
        check(service.referenceWord(id,10,0).equals(answer),"opaque choice video resolves owned question");
        learning.result=evaluation(true,.69,"no_clear_difference");
        JsonNode pending=service.motion(id,10,1,"try1",null);
        check(pending.path("questions").get(1).path("verdict").asText().equals("pending"),"uncertain is pending");
        service.motion(id,10,1,"try1",null); check(learning.calls==1,"duplicate attempt idempotent");
        learning.result=evaluation(true,.95,"low_similarity");
        service.motion(id,10,1,"try2",null); check(learning.calls==2,"pending may be recaptured");
        service.motion(id,10,1,"try3",null); check(learning.calls==2,"final answer immutable");
        String beforeFinish=mapper.find(id,10); rejects(409,()->service.finish(id,10)); check(beforeFinish.equals(mapper.find(id,10)),"invalid finish rolls back");
        for(int i=2;i<10;i++) service.skip(id,10,i);
        JsonNode result=service.finish(id,10); check(result.path("finished").asBoolean(),"finished");
        check(result.path("questions").get(0).path("verdict").asText().equals("correct"),"choice graded server-side");
        check(result.path("questions").get(1).path("verdict").asText().equals("correct"),"similarity not pass cutoff");
        check(result.path("questions").get(1).path("evaluation").path("model_id").asText().equals("test-model"),"model version saved");
        check(!result.path("summary").path("complete").asBoolean(),"pending makes evaluation incomplete");
        check(result.path("summary").path("choice").path("score").isNull(),"no fabricated score for skipped choice");
        check(result.path("summary").path("motion").path("score").isNull(),"no posture pass score");
        check(result.equals(service.finish(id,10)),"finish idempotent");
        rejects(409,()->service.skip(id,10,0));
        JsonNode review=service.start(10,"both","",id); check(review.path("questions").size()==8,"review excludes correct answers");
        JsonNode overall=service.start(10,"both","",""); check(overall.path("questions").size()==14,"overall count");
        Map<String,Integer> counts=new HashMap<>(); int motion=0;
        for(JsonNode q:overall.path("questions")) { counts.merge(q.path("chapter_id").asText(),1,Integer::sum); if(q.path("type").asText().equals("motion"))motion++; }
        check(counts.size()==7&&counts.values().stream().allMatch(v->v==2)&&motion==7,"balanced overall");
        check(service.history(11).isEmpty(),"history owner filter");
        rejects(422,()->service.start(10,"invalid","","")); rejects(422,()->service.start(10,"both","chapter-99",""));
        check(WordExamService.motionVerdict(evaluation(false,.95,"target_mismatch")).equals("incorrect"),"confident mismatch");
        check(WordExamService.motionVerdict(evaluation(true,.99,"insufficient_tracking")).equals("pending"),"tracking failure");
        check(WordExamService.motionVerdict(JSON.createObjectNode().put("status","retry")).equals("pending"),"retry");
        check(WordExamService.motionVerdict(JSON.createObjectNode().put("status","ok")).equals("pending"),"missing recognition");
        JsonNode motionExam=service.start(10,"motion","chapter-02",""); String motionId=motionExam.path("id").asText();
        learning.result=evaluation(true,.5,"uncertain_recognition");
        for(int i=0;i<3;i++) service.motion(motionId,10,0,"pending"+i,null);
        rejects(409,()->service.motion(motionId,10,0,"pending4",null));
        learning.result=evaluation(true,.95,"no_clear_difference"); ((ObjectNode)learning.result).put("model_id","different-model");
        service.skip(motionId,10,0);
        String beforeModelChange=mapper.find(motionId,10);
        rejects(409,()->service.motion(motionId,10,1,"changed",null));
        check(beforeModelChange.equals(mapper.find(motionId,10)),"model change rolls back");
        rejects(422,()->service.motion(motionId,10,1,"bad id",null));
        JsonNode concurrent=service.start(10,"motion","chapter-03",""); String concurrentId=concurrent.path("id").asText();
        int callsBefore=learning.calls;
        java.util.concurrent.ExecutorService pool=java.util.concurrent.Executors.newFixedThreadPool(2);
        try {
            var a=pool.submit(()->service.motion(concurrentId,10,0,"same-attempt",null));
            var b=pool.submit(()->service.motion(concurrentId,10,0,"same-attempt",null));
            a.get(); b.get();
            check(learning.calls==callsBefore+1,"concurrent requests evaluate only once");
            check(JSON.readTree(mapper.find(concurrentId,10)).path("questions").get(0).path("attempts").asInt()==1,"concurrent answers saved once");
        } finally { pool.shutdownNow(); }
        System.out.println("WORD_EXAM_OK checks="+checks);
    }
}
