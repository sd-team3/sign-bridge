# -*- coding: utf-8 -*-
"""
국립국어원 '일상생활수어' API 전체 데이터를 sign_word 테이블에 배치 적재한다.
- 1회성 배치 스크립트 (실시간 호출 아님)
- UNIQUE KEY(sign_word_name) 기준으로 이미 있으면 UPDATE, 없으면 INSERT
- view_count는 이미 존재하는 단어라면 절대 건드리지 않는다 (사용자 조회수 보존)
"""

import re
import time
import xml.etree.ElementTree as ET

import pymysql
import requests

# API 설정 
SERVICE_KEY = "b4215e06-89a0-46d9-9529-d58849a6ce6e"
BASE_URL = "https://api.kcisa.kr/openapi/service/rest/meta13/getCTE01701"
NUM_OF_ROWS = 100  # 한 페이지당 요청 개수
REQUEST_INTERVAL_SEC = 0.2  # API 서버 부담 줄이기용 딜레이

# DB 설정 
DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "yoonjae1102@",
    "database": "sign-bridge",
    "charset": "utf8mb4",
}

# 초성 추출용 상수 (유니코드 완성형 한글 = 가(0xAC00) 시작, 초성 19개 반복 주기)
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
    if 0 <= code <= 11171:  # 완성형 한글 범위
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
    res.raise_for_status()
    return res.text


def parse_items(xml_text: str):
    root = ET.fromstring(xml_text)
    total_count = int(root.findtext(".//totalCount", "0"))
    items = []
    for item in root.findall(".//item"):
        title = (item.findtext("title") or "").strip()
        if not title:
            continue  # 단어명 없는 항목은 스킵
        items.append({
            "name": title,
            "video": (item.findtext("subDescription") or "").strip() or None,
            "thumbnail": (item.findtext("referenceIdentifier") or "").strip() or None,
            "description": (item.findtext("signDescription") or "").strip() or None,
            "api_id": extract_api_id(item.findtext("url") or ""),
            "choseong": extract_choseong(title),
        })
    return items, total_count


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
            # 1페이지분 먼저 적재
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