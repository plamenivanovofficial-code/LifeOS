import datetime as dt

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .models import Memory, SyncState, utcnow, to_utc
from .schemas import MemoryIn


async def _next_rev(session: AsyncSession) -> int:
    state = await session.get(SyncState, 1)
    if state is None:
        state = SyncState(id=1, last_seq=0)
        session.add(state)
    state.last_seq += 1
    await session.flush()
    return state.last_seq


async def upsert(session: AsyncSession, incoming: MemoryIn) -> Memory | None:
    """
    Прилага един входящ запис. Last-write-wins по updated_at.
    Връща записа, ако е приложен; None, ако е отхвърлен (стара версия).
    """
    text = (incoming.text or "").strip()
    incoming_updated = to_utc(incoming.updated_at) if incoming.updated_at else utcnow()

    existing = await session.get(Memory, incoming.id)
    if existing is not None:
        # ако сървърската версия е по-нова, пазим нея
        if existing.updated_at and to_utc(existing.updated_at) >= incoming_updated:
            return None
        if not text and not incoming.deleted:
            return None
        existing.text = text or existing.text
        existing.kind = incoming.kind or existing.kind
        existing.deleted = incoming.deleted
        existing.updated_at = incoming_updated
        existing.rev = await _next_rev(session)
        return existing

    if not text and not incoming.deleted:
        return None

    mem = Memory(
        id=incoming.id,
        text=text,
        kind=incoming.kind or "note",
        created_at=incoming.created_at or utcnow(),
        updated_at=incoming_updated,
        deleted=incoming.deleted,
        rev=await _next_rev(session),
    )
    session.add(mem)
    return mem


async def pull(session: AsyncSession, since: int) -> tuple[list[Memory], int]:
    """Всичко, променено след курсора `since` — включително изтритите, за да се разпространят."""
    rows = (
        await session.execute(
            select(Memory).where(Memory.rev > since).order_by(Memory.rev.asc())
        )
    ).scalars().all()
    cursor = rows[-1].rev if rows else since
    return list(rows), cursor
