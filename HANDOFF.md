# Localmart implementation handoff

Last updated: 2026-11-20

This is the operational handoff for the current demo-enablement work. Read
`CONTEXT.md` for the product and application overview, `CLAUDE.md` for repository
rules, and `docs/DEVELOPMENT.md` for the intended setup workflow.

## Goal and decisions

- Local development: self-hosted Coder Community on this Mac, using Docker
  Desktop and a repository Dev Container.
- Public demo: two Vercel Hobby projects for the Next.js web app and Hono API,
  Supabase Free for PostgreSQL (chosen 2026-11-20 over Neon), and Clerk Free
  for authentication.
- Clerk: use the **development** instance keys (`pk_test_…`/`sk_test_…`) for
  both local and the Vercel demo. Clerk production instances require an owned
  custom domain and do not work on `*.vercel.app`. Switch to a production
  instance only if a domain is bought.
- Expected early hosting cost: $0, excluding an optional domain.

A Supabase project and a Clerk development application exist; their
secrets are in the local, ignored `.env`. No Vercel project exists yet.

## Status: local Coder environment — DONE

Verified 2026-11-20 from a clean Dev Container rebuild:

- Both Coder agents connected and healthy. The nested agent is now named
  `localmart` (from `customizations.coder.name`), so use
  `coder ssh localmart-dev.localmart`.
- `node_modules` and the pnpm store are named Docker volumes inside the Dev
  Container; the host checkout's `node_modules` is no longer written to.
- `make setup` / `make dev` work; migrations and seed succeed.
- Smoke test passed: API `/health` returns `status: "ok"`; web `/`,
  `/communities/portland`, and `/merchants/merchant_dev_001` return 200 and
  render Portland, Rose City Books, and all three published products.
- `coder/.terraform.lock.hcl` generated (linux arm64/amd64, darwin arm64) and
  the template pushed to the local Coder deployment.

Fixes made during this verification (all uncommitted):

- `turbo.json`: Turbo 2 strict env mode was stripping `DATABASE_URL` (migrations
  fell back to localhost) and would have stripped `NEXT_PUBLIC_*`/Clerk keys
  on Vercel. Added `globalPassThroughEnv` and `env: ["NEXT_PUBLIC_*"]`.
- `turbo.json`: `dev` now `dependsOn: ["^build"]` so `@localmart/db` and
  `@localmart/types` `dist/` exist on a fresh checkout (the API crashed
  without them).
- `.devcontainer/devcontainer.json`: `postCreateCommand` chowns the
  root-owned volume mount points before `pnpm install` (was EACCES);
  `displayApps` keys use underscores (`vscode_insiders`, `web_terminal`).
- The old Dev Container predated the volume mounts and was reused on restart;
  it was deleted and recreated. `docs/DEVELOPMENT.md` documents how.

### Host `node_modules` needs a reinstall

Before the rebuild, the container's `pnpm install` overwrote the host
`node_modules` with Linux-only native binaries (esbuild, Next SWC, turbo).
Running pnpm/turbo/next directly on the Mac will fail until `pnpm install` is
run once on the host.

## Status: Supabase — DONE

- Supabase Free project in US East (`aws-1-us-east-1` pooler), PostgreSQL 17.
- Migrations 0000–0002 applied and seed loaded (2026-11-20). `0002_enable_rls`
  is verified: RLS is on for all six tables, the owner role still reads data,
  and Supabase's `anon` role is denied on every table.
- Data API disabled by the user. RLS migration adds a second layer.
- The session pooler URL is in the local `.env` as `SUPABASE_SESSION_URL`
  (used only for migrations/seed from the dev container).

## Status: Vercel demo — two projects

A single project with Vercel Services was tried (PR #4) and failed at deploy
time: "Edge Runtime is not supported in services. Service "web" produced Edge
Function output "src/middleware"". On Next.js 14 middleware always runs on
Edge, and Clerk's `auth()` requires `clerkMiddleware`, so the middleware cannot
be dropped. An offline `vercel build` does not catch this; the check runs on
Vercel's side.

The deployment is therefore two projects (see "Public prototype on Vercel" in
`docs/DEVELOPMENT.md`):

- `apps/api` project: `apps/api/vercel.json` (Hono). Env: `DATABASE_URL`
  (Supabase transaction pooler, 6543), `CLERK_SECRET_KEY`,
  `CLERK_WEBHOOK_SECRET`, `LOG_LEVEL=info`.
- `apps/web` project: `apps/web/vercel.json` (Next.js). Env: `API_URL` (API
  project URL; server-only, read at request time),
  `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`.
- The API serves routes at `/` and under `/api`; either works for the Clerk
  webhook (`https://<api-host>/users`).

Revisit Services after upgrading to Next.js 15.5+ (Node.js middleware) and
Clerk v6 (async `auth()`).

## Known follow-ups

- Upgrade Next.js 14 → 15.5+/16 and Clerk v5 → v6 (async `auth()`), then
  consider moving back to a single Vercel Services project. `apps/web` lint
  uses only `next/core-web-vitals`; it could also extend the shared strict
  config.
- The merchant page's back link goes to `/` instead of the merchant's
  community; a proper link needs the community slug (e.g. from the API).
- `GET /merchants` returns owner email/phone publicly; decide whether that is
  intended before the public demo.
- Update `CONTEXT.md`'s "Immediate next task" once the demo is live.
- Consider a small automated API health test; there is no test suite.
- Once committed and pushed, new Coder workspaces can omit `local_repo_path`
  and clone from GitHub.
