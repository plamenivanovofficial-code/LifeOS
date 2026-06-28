from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # За production в docker-compose това се подменя с postgres+asyncpg URL.
    # По подразбиране sqlite, за да тръгне локално без нищо.
    database_url: str = "sqlite+aiosqlite:///./data/northos.db"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
