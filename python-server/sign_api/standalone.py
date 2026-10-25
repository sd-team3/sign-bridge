from fastapi import FastAPI
from .api import router

app = FastAPI(title='Sign words API')
app.include_router(router)
from .video_api import video_router
app.include_router(video_router)
