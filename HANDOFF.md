# Localmart implementation handoff

Last updated: 2026-11-20

This is the operational handoff for the current demo-enablement work. Read
`CONTEXT.md` for the product and application overview, `CLAUDE.md` for repository
rules, and `docs/DEVELOPMENT.md` for the intended setup workflow.

## Goal and decisions

- Local development: self-hosted Coder Community on this Mac, using Docker
  Desktop and a repository Dev Container.
- Public demo: Vercel Hobby for the Next.js web app and Hono API, Supabase Free
  for PostgreSQL (chosen 2026-11-20 over Neon; the user has contacts there), and Clerk Free for authentication.
- Clerk: use the **development** instance keys (`pk_test_…`/`sk_test_…`) for
  both local and the Vercel demo. Clerk production instances require an owned
  custom domain and do not work on `*.vercel.app`. Switch to a production
  instance only if a domain is bought.
- Expected early hosting cost: $0, excluding an optional domain.

No Vercel or Supabase resources have been created yet. A Clerk development
application exists and its keys are in the local, ignored `.env`.

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

## Status: Vercel demo — repository READY, cloud resources NOT created

Added `apps/api/vercel.json` and `apps/web/vercel.json`. Each sets the
framework and a build command that runs Turbo from the repo root so workspace
packages are compiled first. Verified in a fresh copy of the repo inside the
Dev Container:

- `turbo run build --filter=@localmart/api^...` succeeds, and the Hono app from
  `src/app.ts` serves `/communities` under `NODE_ENV=production`. Vercel's Hono
  detection checks `src/app.ts` before `src/index.ts`, so it picks the
  exported app rather than the Node server.
- `turbo run build --filter=@localmart/web` (full `next build`) succeeds.

CORS is **not** required: every web→API call happens in server components or
server actions (`apps/web/src/lib/api.ts`, `api-auth.ts`), never in the browser.

`packages/db/src/client.ts` disables prepared statements when `VERCEL` is
set, as Supabase's transaction pooler requires.

Remaining steps (need the user's Vercel/Supabase logins and approval):

1. Create a Supabase Free project; copy the session pooler (5432) and
   transaction pooler (6543) connection strings. PostGIS is optional: the
   schema does not use it yet.
2. Run `pnpm db:migrate` and `pnpm db:seed` against the session pooler URL
   from a trusted shell.
3. Create Vercel project for `apps/api` (root directory `apps/api`); set
   `DATABASE_URL` (transaction pooler, port 6543), `CLERK_SECRET_KEY`, `CLERK_WEBHOOK_SECRET`, `LOG_LEVEL=info`.
   Deploy, confirm `/health`.
4. Create Vercel project for `apps/web` (root directory `apps/web`); set
   `NEXT_PUBLIC_API_URL` (API production URL),
   `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`. Deploy.
5. In Clerk: add the web origin; create the user webhook to
   `https://<api-host>/users`; put its signing secret in the API project's
   `CLERK_WEBHOOK_SECRET` and redeploy the API.
6. Public end-to-end smoke test (browse, sign up, merchant apply).

## Known follow-ups

- `apps/api` has no ESLint config, so `pnpm lint` fails for it. The shared
  `packages/config/eslint-base.js` exists but is not wired up; enabling it
  will likely surface real lint errors. (`apps/web` also has no config.)
- The merchant page's back link goes to `/` instead of the merchant's
  community; a proper link needs the community slug (e.g. from the API).
- `GET /merchants` returns owner email/phone publicly; decide whether that is
  intended before the public demo.
- Update `CONTEXT.md`'s "Immediate next task" once the demo is live.
- Consider a small automated API health test; there is no test suite.
- Once committed and pushed, new Coder workspaces can omit `local_repo_path`
  and clone from GitHub.
