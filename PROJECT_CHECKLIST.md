# PROJECT_CHECKLIST.md

> Updated on every major change. Only mark `- [x]` when build + tests + `/health/ready` pass.

## Backend
- [x] (2026-10-01) AGENTS.md created
- [x] (2026-10-01) Repo structure (src/Api, SharedKernel, BuildingBlocks, Modules/*, Infrastructure, tests, apps)
- [x] (2026-10-01) API host (Program.cs, JWT auth, health `/health/live|ready`, OpenAPI, CorrelationId)
- [x] (2026-10-01) SharedKernel (Result, Error, Entity, PagedResult)
- [x] (2026-10-01) BuildingBlocks (JwtOptions/TokenService, IFileStorage/LocalDisk, error envelope)
- [x] (2026-10-01) Identity (User/RefreshToken, BCrypt, AuthService register/login/refresh/logout, RBAC roles)
- [x] (2026-10-01) Users (UserProfile)
- [x] (2026-10-01) Locations (City/Locality + seed Mumbai/Pune/Bengaluru)
- [x] (2026-10-01) Properties (Property aggregate, invariants, publish/pause/sold/rented, search controller w/ geo radius cap 50km)
- [x] (2026-10-01) Postgres/PostGIS AppDbContext + Initial migration + seed
- [x] (2026-10-02) Properties search `?mine=true&ownerId=` (owner dashboard; 401 when anonymous) + phone validation on register
- [ ] Favorites (saved properties + saved searches)
- [ ] Enquiries (lead pipeline New→Contacted→Visited→Closed/Spam, no self-contact)
- [ ] Chat (conversations/messages REST MVP)
- [ ] SiteVisits (future-only scheduling + status)
- [ ] Media (presigned S3/MinIO + variants)
- [ ] Search/OpenSearch sync (background indexer + fallback)
- [ ] Redis (refresh allowlist, rate-limit, search cache, idempotency)
- [ ] Notifications/Verification/Subscriptions/Payments/Admin/Audit

## Mobile (Flutter)
- [x] (2026-10-01) Foundation (pubspec Riverpod/go_router/dio/secure_storage/flutter_map, clean architecture folders)
- [x] (2026-10-01) Auth (login/register, secure token store, 401→refresh interceptor, role guard)
- [x] (2026-10-02) Auth UX overhaul (validated login/register, show/hide password, strength meter, confirm, terms, roles, phone, backend logout, role-based home route, theme Auto/Light/Dark, owner dashboard via mine=true, shared validators/widgets/cards, PropertyQuery value-type fixes refetch loop)
- [x] (2026-10-02) Landing-quality home (hero, Buy/Rent/Commercial deep links, featured carousel, popular locations, post CTA, pull-to-refresh, retry states)
- [ ] Map search (flutter_map + radius)
- [ ] Media upload (image_picker → presigned/multipart)
- [ ] Enquiries/Chat/Visits screens
- [ ] Widget tests (search filter, auth guard)

## Web/Admin (React)
- [x] (2026-10-01) Foundation (Vite+TS, router, TanStack Query, axios refresh interceptor, Tailwind, leaflets)
- [x] (2026-10-02) Landing page (hero search w/ Buy/Rent/Commercial tabs + location/type/budget/BHK, featured, popular locations, how-it-works, post CTA, Navbar w/ mobile menu + role links, Footer, light/dark theme)
- [x] (2026-10-02) Login (validation, show/hide, remember-me local/session, forgot-password dialog, loading guard, friendly API errors, role redirect, logged-in redirect)
- [x] (2026-10-02) Registration (roles, phone, strength meter, confirm, terms, duplicate-submit guard, 409 taken → friendly copy, onboarding redirect to dashboard/home)
- [x] (2026-10-02) Search rewrite (URL-synced filters, sort, skeletons, retry, empty states) + Detail overhaul + lister Dashboard (`mine=true`) + route guards (RequireAuth/Lister/Admin) + reusable ui/PropertyCard/SearchBar/ThemeToggle
- [x] (2026-10-02) Mobile OTP auth a la 99acres (OtpCode entity + migration, LogOtpSender gateway abstraction, purpose-JWT verify tokens, request 60s cooldown/5 attempts/5-min TTL/single-use, unique phone index, 15 unit tests, request/verify/login/register endpoints; MapInboundClaims bug caught by tests)
- [x] (2026-10-02) Web OTP login (Mobile OTP default tab + Email tab, 6-box input w/ paste, resend timer, dev-code banner, new-number → verified registration handoff) + verified-phone registration (inline OTP verify, ✓ badge, otp register call)
- [x] (2026-10-02) Flutter OTP parity (OTP/Email tabs, OtpBoxes, resend cooldown, pendingOtp handoff to register, verified badge, strict mobile validators)
- [x] (2026-10-02) Verified E2E live: request→devCode→cooldown 429→wrong-code 401 w/ attempts→verify isNewUser→register→login→single-use 401; 21/21 tests pass; screenshots inspected
- [ ] Owner dashboard + listing editor + media upload
- [ ] Admin users/listings/verification/plans/reports
- [ ] Vitest coverage

## Infra / Tests / Quality
- [x] (2026-10-01) docker-compose (db postgis:16-3.4, redis:7, opensearch:2.15, minio, api, web) + Dockerfiles
- [x] (2026-10-01) .env.example / .gitignore / .editorconfig / README
- [x] (2026-10-01) Backend unit tests (Property invariants 5/5 passing)
- [ ] Integration tests (auth flow, create→publish→search, favorites, enquiry, visit, moderation)
- [ ] Rate limiting + idempotency + audit logs
- [ ] Serilog JSON + OpenTelemetry + slow-query log
