import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import HTMLResponse

from .db import engine, Base, SessionLocal
from .models import SyncState
from .routers import memories, sync

WEB = os.path.join(os.path.dirname(__file__), "web", "index.html")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dev: създаваме таблиците при старт. Production: тук влиза Alembic (виж README).
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with SessionLocal() as s:
        if await s.get(SyncState, 1) is None:
            s.add(SyncState(id=1, last_seq=0))
            await s.commit()
    yield


app = FastAPI(title="NorthOS", lifespan=lifespan)
app.include_router(memories.router)
app.include_router(sync.router)


@app.get("/health")
async def health():
    return {"ok": True}


@app.get("/", response_class=HTMLResponse)
async def home():
    with open(WEB, "r", encoding="utf-8") as f:
        return HTMLResponse(f.read())
