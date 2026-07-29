import os
import re
import requests
import xml.etree.ElementTree as ET
import pymysql
import time
import html

# properties 파싱.
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
    # Docker 전용 호스트명은 로컬 실행 환경에서는 localhost로 대체
    if host == "host.docker.internal":
        host = "localhost"
    return host, int(port), dbname

# 경로 찾기
PROPS_DIR = os.path.join(
    os.path.dirname(__file__),
    "..", "spring-server", "src", "main", "resources", "properties"
)

app_props = load_properties(os.path.join(PROPS_DIR, "app.properties"))
db_props = load_properties(os.path.join(PROPS_DIR, "db.properties"))

db_host, db_port, db_name = parse_jdbc_url(db_props["db.url"])

# API 설정
SERVICE_KEY = app_props.get("culture.api.serviceKey")
BASE_URL = "https://api.kcisa.kr/openapi/service/rest/meta13/getCTE01701"
NUM_OF_ROWS = 100
REQUEST_INTERVAL_SEC = 0.2

# DB 설정
DB_CONFIG = {
    "host": db_host,
    "port": db_port,
    "user": db_props.get("db.username"),
    "password": db_props.get("db.password"),
    "database": db_name,
    "charset": "utf8mb4",
}

# 초성 추출 >> db초성 컬럼에 적재
CHOSEONG_LIST = [
    "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ",
    "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
]


def extract_choseong(word: str):
    """단어의 첫 글자에서 초성을 뽑아낸다. 한글이 아니면 None."""
    if not word:
        return None
    first_char = word[0]
    code = ord(first_char) - 0xAC00
    if 0 <= code <= 11171:  # 완성형 한글 범위 밖이면 기타,영문
        return CHOSEONG_LIST[code // 588]
    return None


def extract_api_id(url: str):
    """url 필드에서 origin_no 값을 뽑아 sign_word_api_id로 사용한다."""
    if not url:
        return None
    m = re.search(r"origin_no=(\d+)", url)
    return m.group(1) if m else None


def fetch_page(page_no: int):
    params = {
        "serviceKey": SERVICE_KEY,
        "numOfRows": NUM_OF_ROWS,
        "pageNo": page_no,
        "keyword": "",
    }
    res = requests.get(BASE_URL, params=params, timeout=10)
    res.raise_for_status() # 200시 통과
    return res.text

# xml파싱 후 객체 전환
def parse_items(xml_text: str):
    root = ET.fromstring(xml_text)
    total_count = int(root.findtext(".//totalCount", "0"))
    items = []
    for item in root.findall(".//item"):
        title = html.unescape((item.findtext("title") or "").strip())
        if not title:
            continue  # 단어명 없는 항목은 스킵
        description = html.unescape((item.findtext("signDescription") or "").strip()) or None
        items.append({
            "name": title,
            "video": (item.findtext("subDescription") or "").strip() or None, # 빈문자열 허용 x 
            "thumbnail": (item.findtext("referenceIdentifier") or "").strip() or None,
            "description": description,
            "api_id": extract_api_id(item.findtext("url") or ""),
            "choseong": extract_choseong(title),
        })
    return items, total_count

# 기존값 유지하지만, 새로 들어온 값 있으면 새로고침
def upsert_items(cursor, items):
    sql = """
        INSERT INTO sign_word
            (sign_word_name, choseong, sign_word_video, sign_word_thumbnail,
             description, sign_word_api_id)
        VALUES
            (%(name)s, %(choseong)s, %(video)s, %(thumbnail)s,
             %(description)s, %(api_id)s)
        ON DUPLICATE KEY UPDATE
            sign_word_video     = VALUES(sign_word_video),
            sign_word_thumbnail = VALUES(sign_word_thumbnail),
            description         = COALESCE(VALUES(description), description),
            sign_word_api_id    = VALUES(sign_word_api_id)
    """
    cursor.executemany(sql, items)

# 페이지 요청해서 api 아이템 값들 획득
def main():
    print("첫 페이지 조회해서 totalCount 확인 중...")
    xml_text = fetch_page(1)
    items, total_count = parse_items(xml_text)
    total_pages = (total_count // NUM_OF_ROWS) + (1 if total_count % NUM_OF_ROWS else 0)
    print(f"totalCount={total_count}, 총 {total_pages}페이지 예정")

    conn = pymysql.connect(**DB_CONFIG)
    inserted_total = 0

    try:
        with conn.cursor() as cursor:
            # 1페이지분 먼저 적재 >> totalCount 인지하고 total_pages 계산
            if items:
                upsert_items(cursor, items)
                inserted_total += len(items)
                conn.commit()
            print(f"[1/{total_pages}] {len(items)}건 처리")

            for page_no in range(2, total_pages + 1):
                time.sleep(REQUEST_INTERVAL_SEC)
                xml_text = fetch_page(page_no)
                page_items, _ = parse_items(xml_text)
                if page_items:
                    upsert_items(cursor, page_items)
                    conn.commit()
                    inserted_total += len(page_items)
                print(f"[{page_no}/{total_pages}] {len(page_items)}건 처리")

    finally:
        conn.close()

    print(f"\n완료. 총 {inserted_total}건 적재(또는 갱신)했습니다.")


if __name__ == "__main__":
    main()