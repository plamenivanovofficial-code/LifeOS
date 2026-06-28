from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from .. import crud
from ..db import get_session
from ..models import SyncState
from ..schemas import PushIn, PushOut, PullOut, MemoryOut

router = APIRouter(prefix="/api/sync", tags=["sync"])


@router.get("/pull", response_model=PullOut)
async def pull(since: int = Query(0, ge=0), session: AsyncSession = Depends(get_session)):
    rows, cursor = await crud.pull(session, since)
    return PullOut(memories=[MemoryOut.model_validate(r) for r in rows], cursor=cursor)


@router.post("/push", response_model=PushOut)
async def push(body: PushIn, session: AsyncSession = Depends(get_session)):
    applied: list[str] = []
    for incoming in body.memories:
        mem = await crud.upsert(session, incoming)
        if mem is not None:
            applied.append(mem.id)
    await session.commit()
    state = await session.get(SyncState, 1)
    cursor = state.last_seq if state else 0
    return PushOut(applied=applied, cursor=cursor)
