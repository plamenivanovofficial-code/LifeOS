import datetime as dt

from sqlalchemy import String, Boolean, Integer, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def utcnow() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def to_utc(value: dt.datetime) -> dt.datetime:
    """SQLite връща наивни времена; нормализираме всичко към aware UTC."""
    if value.tzinfo is None:
        return value.replace(tzinfo=dt.timezone.utc)
    return value.astimezone(dt.timezone.utc)


class Memory(Base):
    """
    Едно нещо от живота ти. Всичко е Memory — разход, идея, задача, тренировка.
    Типизирането (kind) идва по-късно; днес всичко е 'note'.

    id            : клиентски UUID — глобално уникален, за да работи sync без сблъсъци
    rev           : сървърен монотонен номер; курсорът за изтегляне (pull) стъпва на него
    deleted       : меко изтриване — нищо не се губи, само се скрива
    created_at    : кога се е случило (клиентско време)
    updated_at    : кога е променено последно — основата на last-write-wins
    """
    __tablename__ = "memory"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    kind: Mapped[str] = mapped_column(String(32), default="note", nullable=False)
    created_at: Mapped[dt.datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[dt.datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    rev: Mapped[int] = mapped_column(Integer, index=True, default=0, nullable=False)


class SyncState(Base):
    """Един ред, един брояч. Дава монотонни rev номера на всеки запис."""
    __tablename__ = "sync_state"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    last_seq: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
