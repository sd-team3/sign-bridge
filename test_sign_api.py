import requests

SERVICE_KEY = "b4215e06-89a0-46d9-9529-d58849a6ce6e"
BASE_URL = "https://api.kcisa.kr/openapi/service/rest/meta13/getCTE01701"

params = {
    "serviceKey": SERVICE_KEY,
    "numOfRows": 3,
    "pageNo": 1,
    "keyword": ""  # 문서에 명시된 대로 빈 값이라도 파라미터 자체는 꼭 포함
}

res = requests.get(BASE_URL, params=params)

print("Status Code:", res.status_code)
print("Content-Type:", res.headers.get("Content-Type"))
print("----- RAW RESPONSE -----")
print(res.text)
