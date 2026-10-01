# BuySellProperty — 99acres-inspired Marketplace

Modular monolith: ASP.NET Core (.NET 10) + PostgreSQL/PostGIS + Redis + OpenSearch + S3-compatible storage, Flutter (mobile) + React (web/admin).

See `AGENTS.md` (source of truth) and `PROJECT_CHECKLIST.md` (progress).

## Quickstart (dev)

```bash
cp .env.example .env
docker compose up -d db redis opensearch minio   # infra only
dotnet run --project src/Api                     # API on http://localhost:5000
# health
curl http://localhost:5000/health/ready

# web
cd apps/web && npm install && npm run dev        # http://localhost:3000

# mobile
cd apps/mobile && flutter pub get && flutter run --dart-define API_BASE_URL=http://10.0.2.2:5000

# tests
dotnet test
```

## API surface (v1)

Interactive docs (Development): Swagger UI at `http://localhost:5000/swagger` (Authorize button takes the login `accessToken`), raw JSON at `/swagger/v1/swagger.json`.

- `POST /api/v1/auth/register|login|refresh|logout`, `GET /api/v1/auth/me`
- `POST /api/v1/auth/otp/request|verify|login|register` (mobile OTP, 99acres-style)
- `GET /api/v1/cities`, `GET /api/v1/localities?cityId=`, `GET /api/v1/amenities`
- `GET /api/v1/properties` (search w/ filters + geo), `POST /api/v1/properties`,
  `GET/PATCH/DELETE /api/v1/properties/{id}`, `POST /api/v1/properties/{id}/publish`
- Next: favorites, enquiries, chat, site-visits, verification, subscriptions, payments, admin (see AGENTS.md §6).

## Migrations

```bash
dotnet ef migrations add <Name> --project src/Infrastructure --startup-project src/Api
dotnet ef database update --project src/Infrastructure --startup-project src/Api
```

## Notes

- JWT access 15 min + rotating opaque refresh (SHA256-hashed in DB).
- One `AppDbContext`, schema-per-module (`identity`, `users`, `properties`, `locations`, …).
- Search tries OpenSearch, falls back to Postgres (MVP: Postgres primary).
- `Seed:Enabled=true` auto-migrates + seeds cities in dev.
