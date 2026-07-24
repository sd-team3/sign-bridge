import json
import os
import requests
import pymysql
from datetime import datetime

# ==========================================
# 1. 설정 및 환경 변수
# ==========================================
STATE_FILE = "api_progress.json"
DAILY_LIMIT = 990

API_KEY = "b4215e06-89a0-46d9-9529-d58849a6ce6e"
API_URL = "https://api.kcisa.kr/openapi/service/rest/meta13/getCTE01701"

DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'yoonjae1102@',
    'database': 'sign-bridge',
    'charset': 'utf8mb4'
}

def get_choseong(text):
    if not text:
        return None
    CHOSEONG_LIST = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
    first_char = text[0]
    if '가' <= first_char <= '힣':
        char_code = ord(first_char) - 44032
        return CHOSEONG_LIST[char_code // 588]
    return None

def load_state():
    today_str = datetime.now().strftime("%Y-%m-%d")
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            state = json.load(f)
        if state.get("last_date") != today_str:
            state["call_count"] = 0
            state["last_date"] = today_str
            save_state(state)
        return state
    else:
        initial_state = {"last_date": today_str, "call_count": 0, "last_page": 1}
        save_state(initial_state)
        return initial_state

def save_state(state):
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=4, ensure_ascii=False)

def save_to_db(items, connection):
    sql = """
    INSERT INTO sign_word (
        sign_word_name, choseong, sign_word_video, sign_word_thumbnail, description, sign_word_api_id
    ) VALUES (
        %s, %s, %s, %s, %s, %s
    )
    ON DUPLICATE KEY UPDATE
        sign_word_video     = VALUES(sign_word_video),
        sign_word_thumbnail = VALUES(sign_word_thumbnail),
        description         = COALESCE(VALUES(description), description),
        sign_word_api_id    = VALUES(sign_word_api_id);
    """
    
    saved_count = 0
    with connection.cursor() as cursor:
        for item in items:
            name = item.get("title") or item.get("subTitle")
            if not name:
                continue
                
            choseong = get_choseong(name)
            video = item.get("movieUrl") or item.get("referenceIdentifier")
            thumbnail = item.get("imageUrl")
            description = item.get("signDescription")
            api_id = item.get("uci") or item.get("cnvId")

            cursor.execute(sql, (name, choseong, video, thumbnail, description, api_id))
            saved_count += 1
            
    connection.commit()
    return saved_count

def main():
    state = load_state()
    current_page = state["last_page"]
    call_count = state["call_count"]

    print(f"🚀 [전량 수집 시작] 이어서 시작할 페이지: {current_page} | 오늘 누적 호출: {call_count}회")

    try:
        conn = pymysql.connect(**DB_CONFIG)
    except Exception as e:
        print(f"❌ DB 연결 실패: {e}")
        return

    try:
        while True:
            if call_count >= DAILY_LIMIT:
                print(f"⚠️ 일일 한도 도달로 중단합니다.")
                break

            params = {
                "serviceKey": API_KEY,
                "numOfRows": "100",  # 👈 한 번에 100개씩 최대치로 땡김 (호출 횟수 최소화)
                "pageNo": str(current_page)
            }
            
            headers = {
                "User-Agent": "Mozilla/5.0",
                "Accept": "application/json",
                "serviceKey": API_KEY
            }
            
            response = requests.get(API_URL, params=params, headers=headers, timeout=10)
            
            call_count += 1
            state["call_count"] = call_count
            state["last_page"] = current_page
            save_state(state)

            if response.status_code == 200:
                try:
                    data = response.json()
                except Exception:
                    print("⚠️ JSON 파싱 실패")
                    break

                items = data.get("response", {}).get("body", {}).get("items", {}).get("item", [])
                
                if isinstance(items, dict):
                    items = [items]

                # 🛑 가져올 데이터가 아예 없으면 끝난 거니까 여기서 자동 종료
                if not items:
                    print("🎉 모든 데이터 전량 수집 완료!")
                    break

                saved_cnt = save_to_db(items, conn)
                print(f"✅ [호출 {call_count}회차] {current_page}페이지 완료 ({saved_cnt}건 DB 적재)")
                
                current_page += 1
            else:
                print(f"❌ API 응답 에러 (HTTP status: {response.status_code})")
                break

    except Exception as e:
        print(f"💥 에러 발생: {e}")
    finally:
        conn.close()
        print(f"🏁 작업 종료. 총 호출 횟수: {state['call_count']}회 / 도달한 페이지: {state['last_page']}")

if __name__ == "__main__":
    main()