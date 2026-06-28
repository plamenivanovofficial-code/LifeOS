import uuid

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .. import crud
from ..db import get_session
from ..models import Memory
from ..schemas import MemoryIn, MemoryOut

router = APIRouter(prefix="/api/memories", tags=["memories"])


@router.get("", response_model=list[MemoryOut])
async def list_memories(session: AsyncSession = Depends(get_session)):
    rows = (
        await session.execute(
            select(Memory).where(Memory.deleted == False).order_by(Memory.created_at.desc())  # noqa: E712
        )
    ).scalars().all()
    return [MemoryOut.model_validate(r) for r in rows]


@router.post("", response_model=MemoryOut)
async def add_memory(body: MemoryIn, session: AsyncSession = Depends(get_session)):
    if not body.text.strip():
        return JSONResponse({"error": "Празна мисъл не се записва."}, status_code=400)
    if not body.id:
        body.id = str(uuid.uuid4())
    mem = await crud.upsert(session, body)
    await session.commit()
    await session.refresh(mem)
    return MemoryOut.model_validate(mem)
