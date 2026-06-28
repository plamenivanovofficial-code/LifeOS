# NorthOS

Твоята външна памет. Едно поле. Записваш мисъл, виждаш я на телефона и компютъра.
Offline-first, твой сървър, твои данни.

> Nothing important gets lost.

Стак: **Flutter** (клиент) · **FastAPI** (sync) · **PostgreSQL** · **Isar** (локална база) · **Docker**.

---

## 1. Backend (пускаш първо)

### С Docker + Postgres (за реално ползване)
```bash
cd infra
docker compose up -d --build
```
Сървърът върви на `http://localhost:8000`. От телефон в същата мрежа: `http://АДРЕС-НА-МАШИНАТА:8000`.

### Бързо, без Docker (SQLite, за проба)
```bash
cd server
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Отвори адреса в браузър — **вграденият уеб клиент работи веднага**, без Flutter.
Това ти стига, за да ползваш NorthOS от днес.

---

## 2. Flutter приложението (истинският клиент)

Изисква инсталиран Flutter SDK.

```bash
cd app
flutter pub get
dart run build_runner build      # генерира Isar кода (memory.g.dart)
flutter run --dart-define=API_BASE=http://АДРЕС-НА-СЪРВЪРА:8000
```

- Android емулатор стига до хоста на `http://10.0.2.2:8000` (това е стойността по подразбиране).
- Истински телефон → сложи реалния IP на машината със сървъра.

UI чете от локалната база (Isar), затова работи и без мрежа. Синхронизацията става тихо на заден план.

---

## 3. Данните ти
- Docker: в Postgres тома `pgdata`. Backup = `pg_dump`.
- SQLite режим: файлът `server/data/northos.db`. Копираш = пълен backup.

---

## Бележки за по-нататък (честно, не скрито)
- Миграциите сега са `create_all` при старт. За production добави **Alembic** (първата инфра стъпка, когато схемата започне да се мени).
- Парола на Postgres в compose е примерна — смени я преди да изложиш сървъра навън.
- За HTTPS отвън сложи reverse proxy (Caddy или Traefik). Нарочно не е включен, за да остане compose-ът прост и работещ.

Виж `docs/ARCHITECTURE.md` за как работи sync-ът.
