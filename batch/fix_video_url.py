import os
import re
import requests
import pymysql
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


def load_properties(filepath):
    props = {}
    with open(filepath, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                props[key.strip()] = value.strip()
    return props


def parse_jdbc_url(jdbc_url):
    """jdbc:mysql://host:port/dbname?... 형태에서 host, port, dbname 추출"""
    m = re.match(r"jdbc:mysql://([^:/]+):(\d+)/([^?]+)", jdbc_url)
    if not m:
        raise ValueError(f"db.url 파싱 실패: {jdbc_url}")
    host, port, dbname = m.group(1), m.group(2), m.group(3)
    if host == "host.docker.internal":
        host = "localhost"
    return host, int(port), dbname


PROPS_DIR = os.path.join(
    os.path.dirname(__file__),
    "..", "spring-server", "src", "main", "resources", "properties"
)

db_props = load_properties(os.path.join(PROPS_DIR, "db.properties"))
db_host, db_port, db_name = parse_jdbc_url(db_props["db.url"])

DB_CONFIG = {
    "host": db_host,
    "port": db_port,
    "user": db_props.get("db.username"),
    "password": db_props.get("db.password"),
    "database": db_name,
    "charset": "utf8mb4",
}

# 커넥션 재사용 + 자동 재시도(타임아웃/5xx 시 최대 2회, 점점 대기시간 늘려가며) 세션
session = requests.Session()
session.headers.update({"User-Agent": "Mozilla/5.0"})
retry = Retry(total=2, backoff_factor=1, status_forcelist=[500, 502, 503, 504])
adapter = HTTPAdapter(max_retries=retry, pool_maxsize=10)
session.mount("http://", adapter)
session.mount("https://", adapter)


def guess_video_url(broken_video_url):
    """썸네일(_215X161.jpg)로 잘못 들어간 URL에서 실제 영상(_700X466.mp4) URL을 유추"""
    return re.sub(r"_215X161\.jpg$", "_700X466.mp4", broken_video_url)


def main():
    conn = pymysql.connect(**DB_CONFIG)
    fixed = 0
    skipped = 0
    failed = 0
    timeout_words = []   # 재시도까지 다 실패한 단어 목록

    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute("""
                SELECT sign_word_id, sign_word_name, sign_word_video, sign_word_thumbnail
                FROM sign_word
                WHERE sign_word_video IS NOT NULL
                  AND sign_word_video NOT LIKE '%.mp4'
            """)
            rows = cursor.fetchall()
            total = len(rows)
            print(f"대상 {total}건")

            for idx, row in enumerate(rows, start=1):
                broken_url = row["sign_word_video"]
                guessed_video = guess_video_url(broken_url)

                if guessed_video == broken_url:
                    print(f"[{idx}/{total}][스킵-패턴불일치] {row['sign_word_name']}")
                    skipped += 1
                    continue

                try:
                    # 이 서버가 HEAD 요청을 제대로 처리하지 못해서 GET(stream)으로 확인
                    res = session.get(guessed_video, timeout=(5, 10), stream=True)
                    res.close()  # 본문은 안 받고 상태코드만 확인 후 바로 연결 종료
                    if res.status_code == 200:
                        new_thumb = row["sign_word_thumbnail"] or broken_url
                        cursor.execute("""
                            UPDATE sign_word
                            SET sign_word_video = %s,
                                sign_word_thumbnail = %s
                            WHERE sign_word_id = %s
                        """, (guessed_video, new_thumb, row["sign_word_id"]))
                        fixed += 1
                        print(f"[{idx}/{total}][성공] {row['sign_word_name']}")
                    else:
                        print(f"[{idx}/{total}][실패-{res.status_code}] {row['sign_word_name']}")
                        failed += 1
                except requests.RequestException as e:
                    print(f"[{idx}/{total}][타임아웃/에러] {row['sign_word_name']}: {e}")
                    timeout_words.append(row["sign_word_name"])

                if idx % 50 == 0:
                    conn.commit()  # 중간중간 커밋해서 도중에 죽어도 결과 보존

            conn.commit()

    finally:
        conn.close()

    print(f"\n완료. 성공 {fixed}건 / 스킵(패턴불일치) {skipped}건 / 실패(404 등) {failed}건 / 타임아웃(재시도필요) {len(timeout_words)}건")
    if timeout_words:
        print("타임아웃 목록:", timeout_words)


if __name__ == "__main__":
    main()