import datetime as dt
from pydantic import BaseModel, ConfigDict, field_validator


def _as_utc(value: dt.datetime) -> dt.datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=dt.timezone.utc)
    return value.astimezone(dt.timezone.utc)


class MemoryIn(BaseModel):
    """Каквото изпраща клиентът при запис/синхронизация."""
    id: str
    text: str
    kind: str = "note"
    created_at: dt.datetime | None = None
    updated_at: dt.datetime | None = None
    deleted: bool = False


class MemoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    text: str
    kind: str
    created_at: dt.datetime
    updated_at: dt.datetime
    deleted: bool
    rev: int

    @field_validator("created_at", "updated_at")
    @classmethod
    def _utc(cls, v: dt.datetime) -> dt.datetime:
        return _as_utc(v)


class PushIn(BaseModel):
    memories: list[MemoryIn]


class PushOut(BaseModel):
    applied: list[str]
    cursor: int


class PullOut(BaseModel):
    memories: list[MemoryOut]
    cursor: int
