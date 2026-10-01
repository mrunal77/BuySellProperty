# AGENTS.md — BuySellProperty (99acres-inspired Marketplace)

> Source of truth for AI agents and human contributors. Follow this file on every change.
> Update this file when major architecture decisions change (per Development Rules).

## 1. Project Goal

Build a property marketplace where:

- **Customers (Buyer/Renter)** can search, filter, save, and enquire about properties; view on map; contact owners/agents; book site visits; chat.
- **Owners / Agents / Builders** can publish and manage listings (CRUD + photos/videos), manage enquiries, chat, site visits, view listing analytics.
- **Admins** can manage users, listings, verification, subscriptions/payments, reports, audit logs.

Single Flutter app with role-based experiences + React web/admin + ASP.NET Core API modular monolith.

## 2. Tech Stack (pinned)

| Layer | Tech |
|---|---|
| Backend | ASP.NET Core Web API / .NET 10, C# 13, nullable + implicit usings enabled |
| DB | PostgreSQL 16 + PostGIS 3.4 (location queries, `geography(Point,4326)`) |
| ORM/Migrations | EF Core 10 + Npgsql.EntityFrameworkCore.PostgreSQL + NetTopologySuite |
| Cache | Redis 7 (StackExchange.Redis) — sessions/refresh allowlist, rate-limit, search cache |
| Search | OpenSearch 2.x — property index synced from Postgres (outbox or background sync for MVP) |
| Storage | S3-compatible (MinIO local) / Azure Blob via abstraction `IFileStorage` |
| Auth | JWT access (15 min) + opaque refresh tokens (rotating, hashed in DB, 30d) |
| Mobile | Flutter 3.x + Dart 3.x, Riverpod + go_router + dio + flutter_map |
| Web/Admin | React 18 + TypeScript 5 + Vite + React Router + TanStack Query + Tailwind |
| Infra dev | Docker Compose (postgres-postgis, redis, opensearch, minio, api, web) |
| Tests | xUnit + FluentAssertions + Moq/NSubstitute; Flutter `flutter_test`; Vitest for web |
| Observability | Serilog JSON logs, OpenTelemetry traces, `/health`, `/health/ready` |

No microservices. Start and stay with **modular monolith** until explicit scale trigger is documented here.

## 3. Repository Structure (mandatory)

```
/AGENTS.md
/PROJECT_CHECKLIST.md
/README.md
/.editorconfig
/.gitignore
/docker-compose.yml
/docker-compose.override.yml (optional local)
/.env.example (never commit .env)
/src/
  Api/                          # ASP.NET Core host only: Program.cs, DI, middleware, controllers/thin endpoints
  SharedKernel/                 # Result, Error, Entity, ValueObjects, DomainEvent, IRepository, pagination
  BuildingBlocks/               # Auth/JWT helpers, file storage abstractions, OpenSearch client wrapper, Redis helpers, middleware
  Modules/
    Identity/                   # Auth, refresh tokens, roles, password hashing
    Users/                      # Profiles (Customer/Owner/Agent/Builder/Admin)
    Properties/                 # Property + Listing aggregates (core domain)
    Locations/                  # Cities, localities,Societies, geo queries
    Media/                      # Uploads, S3 abstraction, image variants
    Amenities/                  # Masters + property-amenity mapping
    Search/                     # Filters DTO, OpenSearch sync + query builder
    Favorites/                  # Saved properties + saved searches
    Enquiries/                  # Lead: contact owner, status pipeline
    Chat/                       # Conversations + messages (SignalR later; REST MVP)
    SiteVisits/                 # Scheduling + status
    Notifications/              # Email/SMS/push outbox
    Verification/               # KYC/listing verification workflow
    Subscriptions/              # Plans + entitlements
    Payments/                   # Orders, webhook handling (stub provider in dev)
    Admin/                      # User/listing moderation, reports
    Audit/                      # AuditLogs interceptor
  Infrastructure/               # AppDbContext, migrations, seed, PostGIS config, Redis/OpenSearch wiring
/tests/
  Api.IntegrationTests/
  Modules.<Name>.UnitTests/ (e.g. Tests.Properties.UnitTests)
/apps/
  mobile/ (flutter)             # lib/src/{core,features/{auth,home,search,property_detail,favorites,enquiries,chat,visits,owner_dashboard,listing_editor,profile}}
  web/ (react+vite+ts)          # src/{routes,features,components,lib}
```

**Rules:**

- `src/Api` contains NO business logic — only composition, controllers, middleware, filters.
- Each `Modules/<Name>/` has: `Domain/` (entities, VOs, domain events, rules), `Application/` (commands/queries, DTOs, validators, interfaces), `Infrastructure/` (EF configs, repositories), `Api/` (controllers/endpoints). Small modules may collapse to single csproj with folders.
- Cross-module calls go via interfaces/events, never direct DbSet of another module's tables. Shared queries live in `Application` with explicit contracts.
- `SharedKernel` has zero dependencies on modules.

## 4. Architecture: Clean + Modular Monolith

```
Api (host) -> Modules.Application -> Modules.Domain
                |-> Infrastructure (EF, Redis, S3, OpenSearch)
SharedKernel at center, depended on by all, depends on none.
```

- Request flow: `Controller -> Application Service/Handler -> Domain Entity (invariants enforced) -> Repository -> EF/Postgres`. Domain events dispatched via MediatR (or minimal mediator) in-process.
- Use **vertical slices per feature** inside modules: `CreateListing`, `UpdateListing`, `SearchProperties`, etc.
- Keep it KISS/YAGNI: no CQRS bus, no saga, no dedicated gateway unless checklist item demands it. MediatR only for commands/queries + domain events.
- Pagination: `?page=1&pageSize=20` -> envelope `{ data, page, pageSize, total }`.
- Error envelope: `{ error: { code, message, details? } }` with RFC-style `code` (e.g. `listing.not_found`). Never leak stack traces in prod.
- Logging: Serilog with CorrelationId; log domain events + slow queries (>500ms).

## 5. Domain Overview (MVP entities)

- **Identity**: `User(id, email unique CITEXT, phone, passwordHash, roles[], isActive, createdAt)`, `RefreshToken(id, userId, tokenHash, expiresAt, revokedAt, replacedBy, deviceInfo)`, `Role`: `Customer, Owner, Agent, Builder, Admin`.
- **Users**: `UserProfile(userId PK, displayName, avatarUrl, userType, companyName?, reraId?, cityId?, isVerified)`.
- **Properties**: `Property(id, title, description, propertyType[Apartment|Villa|Plot|Commercial|...], listingType[Sale|Rent|Lease|PG], price, pricePerSqft?, areaSqft, bedrooms?, bathrooms?, furnishing, floor?, totalFloors?, facing?, status[Draft|Active|Paused|Sold|Rented|Expired|Rejected], ownerId, agentId?, builderId?, addressLine, cityId, localityId, location geography(Point), createdAt, publishedAt)` + `Listing` is publication state of Property (MVP: `Listing == Property + moderation fields`; do NOT create separate table until analytics/subscriptions need it — YAGNI).
- **Locations**: `City(id, name, state, center geography)`, `Locality(id, cityId, name, boundary geography?, center geography)`.
- **Media**: `MediaAsset(id, propertyId, kind[Photo|Video|FloorPlan|Document], url, thumbnailUrl?, sortOrder, sizeBytes, width?, height?)`.
- **Amenities**: `Amenity(id, name, icon, category)`, `PropertyAmenity(propertyId, amenityId)`.
- **Search**: no table; query object `SearchPropertiesQuery(cityId?, localityIds?, type?, listingType?, minPrice?, maxPrice?, beds?, baths?, minArea?, maxArea?, furnishing?, amenities[]?, lat?, lng?, radiusKm?, sort[newest|price_asc|price_desc|area_desc], page, pageSize)`.
- **Favorites**: `Favorite(userId, propertyId, createdAt)` composite PK.
- **Enquiries**: `Enquiry(id, propertyId, buyerId, ownerId/agentId, message, contactPhone, status[New|Contacted|Visited|Closed|Spam], createdAt)`.
- **Chat**: `Conversation(id, enquiryId?, participants[])`, `Message(id, conversationId, senderId, body, createdAt, readAt?)`.
- **SiteVisits**: `SiteVisit(id, propertyId, buyerId, ownerId, scheduledAt, status[Requested|Confirmed|Completed|Cancelled|NoShow], notes?)`.
- **Verification**: `VerificationRequest(id, subjectType[User|Property], subjectId, documents[], status[Pending|Approved|Rejected], reviewerId?, decidedAt?)`.
- **Subscriptions/Payments**: `Plan(id, name, price, listingQuota, featuredQuota, durationDays)`, `Subscription(id, userId, planId, startsAt, endsAt, status)`, `PaymentOrder(id, userId, planId, amount, currency, providerRef, status)`.
- **Audit**: `AuditLog(id, actorId?, action, entityType, entityId, diff jsonb, at)`.

PostGIS: all geo columns `geography(Point,4326)` via NetTopologySuite; queries use `ST_DWithin` / `OrderByDistance`. Always create GiST index.

## 6. Backend Conventions (enforce)

- **.NET**: `dotnet new webapi -n Api` style; `TreatWarningsAsErrors=false` for MVP but `Nullable=enable`, `ImplicitUsings=enable`. Target `net10.0`.
- **Config**: `appsettings.json` + `appsettings.Development.json` + env vars. Options pattern (`JwtOptions`, `PostgresOptions`, `RedisOptions`, `StorageOptions`, `OpenSearchOptions`). Validate on startup (`ValidateDataAnnotations` / `ValidateOnStart`).
- **Secrets**: never hardcode. Use `dotnet user-secrets` locally, env vars / KeyVault in prod. `.env.example` lists keys without values.
- **EF**: one `AppDbContext` in `Infrastructure` (modular monolith = single DB, schema per module via `ToTable("...", schema:"...")` or prefix). Schemas: `identity, users, properties, locations, media, engagement (favorites/enquiries/chat/visits), ops (verification/subs/payments/admin/audit)`. Migrations live in `Infrastructure/Migrations`. Seed via `ModelBuilder.HasData` for masters + `DbSeeder` for dev data behind `Seed:Enabled` flag.
- **Validation**: FluentValidation per command/query; return 400 with `error.details` field errors. Data annotations only for trivial DTOs.
- **Auth**: JWT Bearer (`Microsoft.AspNetCore.Authentication.JwtBearer`). Access claims: `sub, email, roles[], userType`. Short-lived purpose JWTs (`purpose=otp`, 10 min) gate OTP login/registration. Policies: `RequireRole("Owner,Agent,Builder")` for publish; resource-based check (ownerId == sub or Admin) for edit/delete. Refresh: `POST /api/v1/auth/refresh` rotates, sets httpOnly cookie + body token (mobile uses body).
- **Endpoints versioning**: `/api/v1/...`. REST plural nouns. Full MVP surface:
  ```
  POST /api/v1/auth/register  POST /api/v1/auth/login  POST /api/v1/auth/refresh  POST /api/v1/auth/logout  GET /api/v1/auth/me
  POST /api/v1/auth/otp/request  POST /api/v1/auth/otp/verify  POST /api/v1/auth/otp/login  POST /api/v1/auth/otp/register
  GET/POST /api/v1/users  GET/PATCH /api/v1/users/{id}
  GET /api/v1/cities  GET /api/v1/localities?cityId=
  GET /api/v1/amenities
  GET /api/v1/properties (search; `?mine=true` requires auth, returns own listings incl. drafts; `?ownerId=` public filter)  POST /api/v1/properties  GET/PATCH/DELETE /api/v1/properties/{id}  POST /api/v1/properties/{id}/publish  POST /api/v1/properties/{id}/media
  GET/POST /api/v1/favorites  DELETE /api/v1/favorites/{propertyId}
  GET/POST /api/v1/enquiries  PATCH /api/v1/enquiries/{id}
  GET/POST /api/v1/conversations  GET/POST /api/v1/conversations/{id}/messages
  GET/POST /api/v1/site-visits  PATCH /api/v1/site-visits/{id}
  GET/POST /api/v1/verification-requests  PATCH /api/v1/verification-requests/{id}/decision (Admin)
  GET /api/v1/plans  POST /api/v1/subscriptions  POST /api/v1/payments/orders  POST /api/v1/payments/webhooks
  GET /api/v1/admin/users  PATCH /api/v1/admin/users/{id}/status  GET /api/v1/admin/listings/pending  POST /api/v1/admin/listings/{id}/moderate
  ```
- **Idempotency**: `Idempotency-Key` header on POST payments/enquiries (store in Redis 24h).
- **Rate limiting**: login/refresh/register 10/min/IP; search 120/min/IP.
- **File upload**: presigned S3 URLs preferred (`POST /media/presign`); direct multipart max 25MB fallback. Validate MIME + scan stub.
- **Health**: `/health/live`, `/health/ready` (checks postgres, redis, opensearch, storage).

## 7. Database / PostGIS Rules

- Connection via `ConnectionStrings:Default`. Use Npgsql + `UseNetTopologySuite()`. Enable `postgis`, `citext`, `pg_trgm` extensions in migration.
- All tables: `id uuid PK default gen_random_uuid()`, `created_at timestamptz default now()`, `updated_at timestamptz`. Use `snake_case` column names via naming convention or explicit mapping.
- Geo: `Location` mapped `Point` SRID 4326, column type `geography (point)`. Seed cities with real lat/lng.
- Indexes: GiST on geo, GIN trigram on title/description, B-tree on (city_id, status, price).
- Migrations: `dotnet ef migrations add <Name> --project src/Infrastructure --startup-project src/Api`. Never edit applied migration; add new one. Seed masters idempotent.

## 8. Search / Cache / Storage Rules

- **OpenSearch**: index `properties` (id, title, description, type, listingType, price, area, beds, city, locality, amenities[], location lat/lon, status, publishedAt). Sync via `PropertyIndexedEvent` -> background hosted service (MVP polling every 30s is OK). Search API tries OpenSearch, falls back to Postgres if unavailable (log warning).
- **Redis**: keys `refresh:{hash}`, `search:cache:{hash(query)}` TTL 60s, `rate:{ip}:{endpoint}`, `idemp:{key}` TTL 24h. Never cache auth/me or mutations.
- **Storage**: `IFileStorage` with `LocalDisk` (dev) + `S3Compatible` (prod/MinIO). URLs stored absolute; thumbnails generated async (stub in MVP).

## 9. Flutter Conventions (`apps/mobile`)

- Clean architecture: `lib/src/core/{network,auth_store,router,theme,widgets,utils}` + `lib/src/features/<feature>/{data, domain, presentation}`.
- State: Riverpod (`flutter_riverpod`). Routing: `go_router` with `AuthGuard` (redirect `/login` if no token; role guard for `/owner/*`). Network: `dio` with auth interceptor (attach access token, 401 -> refresh, retry once).
- Auth storage: `flutter_secure_storage` for tokens + `userType/roles`.
- Roles: single app, bottom nav switches by `userType`: Customer tabs (Home, Search, Map, Saved, Chats, Profile); Owner/Agent/Builder tabs (Dashboard, Listings, Add, Enquiries, Chats, Profile). Role switcher in profile for demo users with multiple roles.
- Screens MVP: `Login, Register, Home, Search+Filters, MapSearch, PropertyDetail, Favorites, SavedSearches, EnquiryForm, ChatList, ChatDetail, VisitBooking, OwnerDashboard, ListingEditor, MediaUpload, EnquiryInbox, VisitCalendar, AnalyticsStub, Profile`.
- Forms: validate client-side, show server `details` errors inline. Image picker + multipart to `/media` or presigned flow.
- Env: `--dart-define API_BASE_URL=http://localhost:5000` (Android emulator: `http://10.0.2.2:5000`). No secrets in repo.
- Tests: widget test for search filter + auth guard.

## 10. React Web/Admin (`apps/web`)

- Vite + TS strict + ESLint + Prettier. Routes: `/` (storefront search), `/p/:id`, `/login`, `/dashboard`, `/listings/*`, `/enquiries`, `/admin/*` (users, listings/pending, verification, plans, reports).
- Data: TanStack Query + axios instance with refresh interceptor. Auth context with roles. Admin routes gated `role==Admin`.
- UI: Tailwind + headless components; map via `react-leaflet` (OSM tiles, no API key for dev).
- Env: `.env.example` with `VITE_API_URL=http://localhost:5000`.

## 11. Docker Dev Environment

- `docker-compose.yml` services: `db (postgis/postgis:16-3.4)`, `redis:7-alpine`, `opensearch:2.15.0` (+ `opensearch-dashboards` optional), `minio/minio`, `api (build ./src/Api)`, `web (build ./apps/web)`. Flutter runs on host, not in compose.
- Volumes persist db/redis/opensearch/minio. Healthchecks on db/redis/opensearch.
- `.env.example`: `POSTGRES_PASSWORD=, JWT_SECRET=(dev only placeholder), MINIO_ROOT_PASSWORD=, OPENSEARCH_INITIAL_ADMIN_PASSWORD=` — real values only in untracked `.env`.
- Commands: `docker compose up -d db redis opensearch minio` for infra-only; `dotnet run --project src/Api` for API on host; `docker compose up --build` for full stack.

## 12. Testing & Quality Gates

- Backend unit: domain invariants (price>0, area>0, geo valid, status transitions, enquiry cannot self-contact, visit must be future). Integration: auth flow, create->publish->search, favorites, enquiry, visit, admin moderation with Testcontainers or compose DB.
- Run: `dotnet test`, `flutter test`, `npm --prefix apps/web test`. Keep app runnable after every major change: `dotnet build`, `dotnet ef database update` (or compose up), `curl /health/ready` must pass before marking checklist item done.
- Lint/format: `dotnet format`, `dart format`, `npx prettier --check`.

## 13. Security / Perf Checklist (apply to every module)

- [ ] AuthZ on every endpoint (anon only for register/login/search-read).
- [ ] Owner check: `property.ownerId == sub` or Admin; agents scoped to assigned listings.
- [ ] Input validation + max lengths; file MIME/size checks.
- [ ] No secrets/logs with PII; hash refresh tokens (SHA256), bcrypt/Argon2id passwords.
- [ ] N+1 avoided (`Include`/`ProjectTo`); search paginated max 100; geo radius capped 50km.
- [ ] Audit log on moderation, verification decisions, role changes.

## 14. Workflows for Agents

- **Before each module**: inspect existing code (`glob/read/grep`), reuse abstractions from `SharedKernel/BuildingBlocks`, avoid duplication, smallest practical change.
- **After each module**: `dotnet build`, run relevant tests, verify `/health/ready`, update `PROJECT_CHECKLIST.md` (`- [x]` + date), append notes to `README.md` if setup changed.
- **Commits**: conventional (`feat(properties): add publish flow`). Do not commit secrets, `bin/`, `obj/`, `.env`, `apps/mobile/build`.
- **Definition of done**: code + migration + seed (if masters) + tests for business rules + docs updated + app still runs.

## 15. PROJECT_CHECKLIST.md Maintenance

- Keep at repo root. Sections: Backend, Mobile, Web, Infra, Tests. Each item `- [ ]` / `- [x] (YYYY-MM-DD)`.
- Update on every major change. Never mark done unless build + tests + health pass.

## 16. Initial Implementation Order

1. AGENTS.md (this file) 2. Repo structure + .gitignore/.editorconfig/.env.example 3. API host + SharedKernel + BuildingBlocks 4. Postgres/PostGIS + Infrastructure + migrations 5. Identity (JWT+refresh+RBAC) 6. Users/Properties/Listings domains 7. Seed + search/favorites/enquiries/chat/visits 8. Flutter foundation + auth + property screens 9. React foundation + admin 10. Docker + tests + checklist.

---
*Teams: Customer/Buyer/Renter, Owner, Agent, Builder, Admin. Platform inspiration: 99acres. Keep it simple, modular monolith first.*
