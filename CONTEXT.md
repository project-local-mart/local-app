# Localmart — Context for AI Coding Assistants

This document orients an AI assistant picking up work on this repo. It reflects the
actual state of the code as of this writing — not the roadmap's aspirational state.
For conventions and rules (not status), see `CLAUDE.md`. For architectural rationale,
see `docs/decisions/`. For the full build-out plan, see `docs/ROADMAP.md`.

For the latest operational status of the Local Coder + Vercel Hobby demo work,
including the exact resume command and remaining cloud tasks, read `HANDOFF.md`
before making changes.

## What Localmart is

Localmart is an open source, community-governed marketplace connecting independent
local retail businesses with shoppers in their own neighborhoods. Each "community" is
a named geographic area (a set of zip codes) with its own volunteer moderators who
approve merchants and moderate listings. It is centralized infrastructure for v1 by
deliberate choice (see ADR-002) — federation is a possible future direction, not a
current feature.

## Current build status

The project is past initial scaffolding and has a working local dev slice: a real
Postgres schema, a functioning API with auth and role checks, and web pages that
exercise the merchant approval and product-listing flows end to end. It is **not**
deployed anywhere, has no search/queue/storage integrations wired up yet, and has no
AWS infrastructure provisioned (Terraform modules exist as scaffolding only).

**Working locally today:**
- `docker-compose up -d` brings up Postgres 16 + PostGIS, Redis 7, Meilisearch, and
  MinIO — all four containers run, but only Postgres is actually used by application
  code right now. Redis, Meilisearch, and MinIO are provisioned and idle.
- Clerk auth is wired end-to-end: `apps/web` uses `@clerk/nextjs` middleware to gate
  routes; `apps/api` verifies Clerk JWTs per-request and syncs users into Postgres via
  a Clerk webhook handler (`/users` webhook route).
- The Drizzle schema, two generated migrations, and an idempotent seed script all
  exist and run (`pnpm db:generate` / `db:migrate` / `db:seed`).
- The API serves role-checked CRUD for communities, merchants, and products, including
  the merchant approval/rejection/suspension flow and the product moderation flow.
- The web app has real (not placeholder) pages: home, community detail, merchant
  detail, sign-in/sign-up, and a merchant dashboard with an application wizard and
  product create/edit/list screens.

## Tech stack (with versions)

| Layer              | Technology                          | Version         |
|--------------------|--------------------------------------|-----------------|
| Consumer frontend  | Next.js (App Router)                 | 14              |
| Merchant app       | React Native / Expo                  | SDK 51 *(scaffolded only, excluded from workspace)* |
| Backend API        | Hono.js on Node.js                   | Hono ^4.3        |
| Auth               | Clerk (`@clerk/nextjs`, `@clerk/backend`) | ^5.7 / ^3.2 |
| Database           | PostgreSQL with PostGIS extension    | Postgres 16 / PostGIS 3.4 |
| ORM                | Drizzle (`drizzle-orm`, `drizzle-kit`) | ^0.30 / ^0.21  |
| Validation         | Zod                                   | ^3.25           |
| Logging            | pino (structured JSON)               | ^10.3           |
| Search             | Meilisearch                          | v1.7 *(running, unused)* |
| Task queue         | BullMQ + Redis                       | Redis 7 *(running, unused)* |
| Object storage      | MinIO locally → AWS S3 in cloud      | *(running, unused)* |
| Monorepo tooling   | Turborepo + pnpm workspaces           | Turbo ^2.0 / pnpm 9.0 |
| Node               | Node.js                              | ≥20             |

## Monorepo structure

```
apps/
  web/          Next.js 14 consumer + merchant-dashboard frontend
  api/          Hono.js backend — ALL business logic lives here
  merchant/     Expo React Native app — scaffolded, excluded from pnpm workspace
                (re-enabled in pnpm-workspace.yaml at Tier 5 of the roadmap)
packages/
  types/        Domain types shared by every app — edit this FIRST when the model changes
  db/           Drizzle schema (source of truth), migrations, seed script
  config/       Shared ESLint + TypeScript base configs
docs/
  decisions/    ADRs — architectural rationale and constraints
  policies/     Community policy docs (e.g. merchant eligibility rules)
  ROADMAP.md    Full tiered build plan, in dependency order
infra/
  terraform/    AWS modules (networking, database, ecs-cluster, iam, dns-certs, ...)
                Scaffolded only — nothing has been applied to real AWS accounts
```

The dependency direction is strict: `packages/types` → `packages/db` → `apps/api` →
`apps/web`. The web app never imports `@localmart/db` directly; all writes go through
the API.

## Key domain concepts

- **Community** — a named geographic area defined by a list of zip codes. The tenancy
  boundary for the whole platform: merchants, moderators, and (eventually) products
  are all scoped to one community via `communityId`.
- **Merchant** — a local business approved to sell within a community. Has a lifecycle
  status (`pending` → `approved`, or `suspended`/`rejected`) driven by moderator
  review. Eligibility rules (local ownership, operational independence, ≤6 locations,
  no franchise/PE control) are documented in `docs/policies/merchant-eligibility.md`
  and are currently self-declared at signup, not programmatically enforced.
- **Product** — a listing owned by a merchant. Has two independent status axes:
  `moderationStatus` (`pending`/`clean`/`flagged`/`held`, set by a moderator) and
  `isPublished` (a boolean the merchant controls, which can only be flipped to `true`
  once moderation is `clean`). `source` tracks whether it was entered manually or
  synced from a POS system (`square`/`shopify`/`clover`/`csv`) — POS sync itself is
  not implemented yet.
- **Moderator** — a user scoped to exactly one community (`Moderator.communityId`),
  responsible for approving/rejecting/suspending merchants and moderating products in
  that community. Distinct from the `moderator` value of `UserRole` — a `User` carries
  the role; a `Moderator` record is the community assignment.

## Permission model

Four roles, defined in `packages/types` as `UserRole` and enforced in the API via
`requireRole(...)` middleware (`apps/api/src/middleware/rbac.ts`), layered on top of
`verifyAuth` (`apps/api/src/middleware/auth.ts`), which verifies the Clerk JWT and
attaches the synced DB user to the request context:

| Role             | Scope                          | Can do                                                              |
|------------------|---------------------------------|-----------------------------------------------------------------------|
| `platform_admin` | Global, `communityId: null`     | Everything — create communities, approve/reject/suspend any merchant, moderate any product |
| `moderator`      | One community (`communityId` set) | Approve/reject merchants, moderate products — scoped to their community *(scoping is by convention today; not yet enforced by a DB-level check — see Known gaps)* |
| `merchant`       | Their own merchant record        | Create/edit/delete their own products, publish once moderation-clean, edit their own merchant profile |
| `consumer`       | None (default role)              | Apply to become a merchant (creates a `pending` Merchant record); browse public communities/merchants/published products |

## What's built vs. not built yet

**Built:**
- Drizzle schema, migrations, seed script (`packages/db`)
- Clerk auth + webhook user sync, RBAC middleware (`apps/api`)
- CRUD + workflow routes: communities, merchants (apply/approve/reject/suspend),
  products (create/edit/delete/publish/moderate)
- Web: home, community detail, merchant detail, sign-in/up, merchant dashboard
  (apply wizard, product list/create/edit)
- Local Docker environment for all four backing services

**Not built yet:**
- Moderator management endpoints (assign/remove/list moderators for a community —
  the `Moderator` type and roadmap section exist; no route implements it)
- Meilisearch integration — no indexing worker, no `/search` endpoint; `GET /products`
  has no filtering/search, just a flat list scoped by `merchantId`
- BullMQ queues/workers — Redis is running but nothing publishes or consumes jobs
- POS integrations (Square/Shopify/Clover OAuth + sync) — `POSConnection` type exists
  in `packages/types`; no API routes, no worker
- Image upload — MinIO/S3 is running but there's no pre-signed-upload endpoint or
  image-processing pipeline; `Product.images` has to be populated by hand today
- Email sending (merchant welcome/approved/rejected notifications)
- Moderator and platform-admin dashboards in `apps/web` (only the merchant dashboard
  exists)
- Row-level security / DB-level community scoping — `communityId` filtering is
  currently enforced only in application code, not at the database layer
- Any AWS deployment — Terraform modules are scaffolded but never applied; there is
  no Vault, no CI/CD pipeline beyond what's in `.github/workflows`

## Immediate next task

The Tier 1 API surface (communities/merchants/products CRUD + RBAC) is substantially
complete. The two things blocking it from being *fully* done are:

1. **Moderator management routes** — `POST/GET/DELETE` for assigning and removing
   moderators on a community (platform_admin only). This is the one missing piece of
   Tier 1 and is small in scope.
2. **Meilisearch product search** — the service is already running in Docker and
   unused. Next: an indexing step on product create/update/delete (or a sync worker),
   a `GET /v1/search` endpoint proxying to it with community scoping enforced
   server-side, and a real search/filter UI on the web consumer side (today's
   `GET /products` is not a search endpoint).

Once those land, Tier 2 continues with POS integrations and BullMQ workers — see
`docs/ROADMAP.md` for the full ordering.
