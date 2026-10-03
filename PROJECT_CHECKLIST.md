# PROJECT_CHECKLIST.md

> Updated on every major change. Only mark `- [x]` when build + tests + `/health/ready` pass.

## Backend
- [x] (2026-10-01) AGENTS.md created
- [x] (2026-10-01) Repo structure (src/Api, SharedKernel, BuildingBlocks, Modules/*, Infrastructure, tests, apps)
- [x] (2026-10-01) API host (Program.cs, JWT auth, health `/health/live|ready`, OpenAPI, CorrelationId)
- [x] (2026-10-01) SharedKernel (Result, Error, Entity, PagedResult)
- [x] (2026-10-01) BuildingBlocks (JwtOptions/TokenService, IFileStorage/LocalDisk, error envelope)
- [x] (2026-10-01) Identity (User/RefreshToken, BCrypt, AuthService register/login/refresh/logout, RBAC roles)
- [x] (2026-10-02) Users (UserProfile)
- [x] (2026-10-02) Locations (City/Locality + seed Mumbai/Pune/Bengaluru)
- [x] (2026-10-02) Properties (Property aggregate, invariants, publish/pause/sold/rented, search controller w/ geo radius cap 50km)
- [x] (2026-10-02) Postgres/PostGIS AppDbContext + Initial migration + seed
- [x] (2026-10-02) Properties search `?mine=true&ownerId=` (owner dashboard; 401 when anonymous) + phone validation on register
- [x] (2026-10-02) Favorites domain & endpoints (`GET /api/v1/favorites`, `POST /api/v1/favorites`, `DELETE /api/v1/favorites/{id}`)
- [x] (2026-10-02) Enquiries lead pipeline (`POST /api/v1/enquiries`, `GET /api/v1/enquiries?mine=true`, status updates)
- [x] (2026-10-02) SiteVisits scheduling (`POST /api/v1/site-visits`, future-only validation, `GET /api/v1/site-visits`)
- [x] (2026-10-02) Chat REST MVP (`GET/POST /api/v1/conversations`, `GET/POST /api/v1/conversations/{id}/messages`)
- [x] (2026-10-02) Amenities master (`GET /api/v1/amenities` + seed default amenities)
- [x] (2026-10-02) Admin moderation (`GET /api/v1/admin/users`, `PATCH status`, `GET /admin/listings/pending`, `POST moderate`)
- [x] (2026-10-02) Publish Property authorization fix (`[Authorize]` on publish/create/update/delete based on resource ownership, JsonStringEnumConverter registered, verified E2E)

## Mobile (Flutter)
- [x] (2026-10-01) Foundation (pubspec Riverpod/go_router/dio/secure_storage/flutter_map, clean architecture folders)
- [x] (2026-10-01) Auth (login/register, secure token store, 401→refresh interceptor, role guard)
- [x] (2026-10-02) Auth UX overhaul (validated login/register, show/hide password, strength meter, confirm, terms, roles, phone, backend logout, role-based home route, theme Auto/Light/Dark, owner dashboard via mine=true, shared validators/widgets/cards, PropertyQuery value-type fixes refetch loop)
- [x] (2026-10-02) Landing-quality home (hero, Buy/Rent/Commercial deep links, featured carousel, popular locations, post CTA, pull-to-refresh, retry states)
- [x] (2026-10-02) Favorites screen (saved properties with bookmark toggle)
- [x] (2026-10-02) Property detail overhaul (image carousel, spec grid, amenity chips, Contact Owner & Schedule Visit dialogs)
- [x] (2026-10-02) Owner dashboard & Listing editor (post/publish new properties with photos & amenities)
- [x] (2026-10-02) Flutter Widget & Navigation unit tests passing

## Web/Admin (React)
- [x] (2026-10-01) Foundation (Vite+TS, router, TanStack Query, axios refresh interceptor, Tailwind)
- [x] (2026-10-02) Landing page (hero search w/ Buy/Rent/Commercial tabs + location/type/budget/BHK, featured, popular locations, how-it-works, post CTA, Navbar w/ mobile menu + role links, Footer, light/dark theme)
- [x] (2026-10-02) Login & Registration (roles, phone, strength meter, confirm, terms, duplicate-submit guard, friendly copy, onboarding redirect)
- [x] (2026-10-02) Mobile OTP auth a la 99acres (OtpCode entity + migration, LogOtpSender gateway abstraction, purpose-JWT verify tokens, 6-box input w/ paste)
- [x] (2026-10-02) Search rewrite (URL-synced filters, sort, skeletons, retry, empty states) + Detail overhaul (gallery, specs, contact owner enquiry modal, schedule site visit modal, save favorite button)
- [x] (2026-10-02) Favorites route (`/favorites`) with saved properties management
- [x] (2026-10-02) Owner Studio / Dashboard (`/dashboard`) with Post Property listing editor, Enquiries Inbox, and Site Visit inbox tabs
- [x] (2026-10-02) Admin moderation & user management portal (`/admin`)
- [x] (2026-10-02) Clean TypeScript production build (`npm run build` passing)

## Infra / Tests / Quality
- [x] (2026-10-01) docker-compose (db postgis:16-3.4, redis:7, opensearch:2.15, minio, api, web) + Dockerfiles
- [x] (2026-10-01) .env.example / .gitignore / .editorconfig / README
- [x] (2026-10-02) Backend unit and integration tests (21/21 passing)
- [x] (2026-10-02) EF Core migrations (`AddFullMarketplaceModules`) & DbSeeder
- [x] (2026-10-02) Dynamic real estate property count API (`GET /api/v1/cities`) & `city` string filter matching (`GET /api/v1/properties?city=...`)
- [x] (2026-10-02) City filter matching & dynamic property counts on Web and Mobile apps
- [x] (2026-10-02) Mobile Agent workflow (Agent Role switcher, Agent Dashboard at `/agent`, Client Listings, Lead Inbox, Site Visit Calendar, Verified Agent RERA Badge)

