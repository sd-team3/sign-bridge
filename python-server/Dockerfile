FROM python:3.11.9-slim

WORKDIR /app

# mediapipe / opencv 계열은 시스템 라이브러리가 필요
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# 수집 데이터 / 모델이 컨테이너 재생성에도 남아있도록 볼륨 마운트 대상
VOLUME ["/app/data", "/app/model"]

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
