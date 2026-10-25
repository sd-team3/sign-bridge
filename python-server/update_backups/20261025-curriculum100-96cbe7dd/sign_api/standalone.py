"""Isolated smoke-test application; production uses main:app with this router."""
from fastapi import FastAPI
from .api import router

app = FastAPI(title='Sign words API')
app.include_router(router)
