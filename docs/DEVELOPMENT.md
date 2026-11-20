# Local development and prototype deployment

Localmart uses a repository Dev Container so the same development environment
works in VS Code-compatible clients and in a local Coder Community deployment.
The public prototype is one Vercel project (using Vercel Services) backed by a
Supabase PostgreSQL database.

## Local Coder Community

### Prerequisites

- Coder Community 2.24 or later
- Docker Desktop or Colima
- Terraform 1.6 or later

Coder's web UI must not use port `3000`, because the Localmart web app uses that
port. The examples below use `7080`.

### Start the control plane

Install Coder Community's stable CLI in a user-local directory:

```bash
curl -fsSL https://coder.com/install.sh -o /tmp/coder-install.sh
sh /tmp/coder-install.sh --stable --method standalone --prefix "${HOME}/.local"
export PATH="${HOME}/.local/bin:${PATH}"
```

Create Coder's dedicated local PostgreSQL database. It uses port `5433` so it
does not conflict with Localmart's development database on `5432`:

```bash
docker volume create localmart_coder_data
docker run -d --name localmart_coder_postgres \
  -e POSTGRES_USER=coder \
  -e POSTGRES_PASSWORD=coder_local_dev_password \
  -e POSTGRES_DB=coder \
  -p 127.0.0.1:5433:5432 \
  -v localmart_coder_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:16-alpine
```

Start the control plane:

```bash
CODER_HTTP_ADDRESS=127.0.0.1:7080 \
  CODER_ACCESS_URL=http://127.0.0.1:7080 \
  CODER_PG_CONNECTION_URL='postgres://coder:coder_local_dev_password@127.0.0.1:5433/coder?sslmode=disable' \
  coder server
```

When using Colima instead of Docker Desktop, start Colima and export its socket
before starting Coder:

```bash
colima start
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
```

Open <http://127.0.0.1:7080> and complete Coder's initial account setup.

### Push the Localmart template

In a second terminal, from the repository root:

```bash
coder login http://127.0.0.1:7080
coder templates push localmart --directory coder
coder create localmart-dev --template localmart \
  --parameter local_repo_path="$(pwd)"
```

`local_repo_path` bind-mounts the current worktree, including uncommitted files,
and is intended for a Coder deployment running on the same machine. Omit that
parameter to clone the template's Git repository URL instead.

The template automatically starts the repository's Dev Container. Coder will
show the `localmart` sub-agent when the container is ready. Open it with VS Code,
a web terminal, or `coder ssh localmart-dev.localmart`.

The container keeps `node_modules` and the pnpm store in named Docker volumes so
Linux binaries never overwrite the host checkout's dependencies. If the
container was created before those volumes were configured, delete it from the
workspace's Docker daemon and restart the workspace so it is recreated:

```bash
coder ssh localmart-dev.main -- docker ps            # find the Dev Container
coder ssh localmart-dev.main -- docker rm -f <name>
coder restart localmart-dev --yes
```

### Run Localmart

Inside the `localmart` Dev Container:

```bash
make setup
make dev
```

`make setup` creates `.env` from `.env.example`, starts the local backing
services, runs migrations, and inserts demo data. Add Clerk development keys to
`.env` before exercising authenticated merchant flows.

## Public prototype on Vercel

The prototype is a single Vercel project that uses
[Vercel Services](https://vercel.com/docs/services) (beta, available on Hobby).
The root `vercel.json` declares two services built from this repository:

| Service | Root       | Public path        | Notes                                            |
|---------|------------|--------------------|--------------------------------------------------|
| `web`   | `apps/web` | everything else    | Next.js; calls `api` over a private binding      |
| `api`   | `apps/api` | `/api`, `/api/*`   | Hono; entry point `src/app.ts`                   |

Each service's build command runs Turbo from the repository root so
`@localmart/types` and `@localmart/db` are compiled first.

### Database

1. Create a Supabase project in the region closest to the Vercel functions
   (Vercel Hobby functions run in `iad1`, US East, by default).
2. Optional: enable PostGIS under Database → Extensions. The current schema
   stores plain latitude/longitude and does not require it yet.
3. From the project's **Connect** dialog, copy two connection strings:
   - **Session pooler** (port `5432`): for migrations and seeding from a
     local shell. Supabase's direct connection is IPv6-only on the free plan,
     so use the session pooler from home networks.
   - **Transaction pooler** (port `6543`): for the Vercel project's
     `DATABASE_URL`. `packages/db` disables prepared statements on Vercel
     because transaction-mode pooling does not support them.
4. From a trusted local shell, run migrations and seed the demo data with the
   session pooler URL:

```bash
DATABASE_URL='postgresql://...:5432/postgres' pnpm db:migrate
DATABASE_URL='postgresql://...:5432/postgres' pnpm db:seed
```

Do not put connection strings in the repository.

Turn off Supabase's Data API (**Project Settings → Data API**). Localmart only
reaches the database through `apps/api`, and the auto-generated REST API would
otherwise expose the `public` schema to anyone holding the project's anon key.
Migration `0002_enable_rls` also enables deny-by-default row level security on
every table as a second layer; the API connects as the table owner and is
unaffected.

Free Supabase projects pause after about a week without activity and must be
restored from the dashboard. Visit the demo occasionally, or restore the
project before showing it.

### Vercel project

1. **Add New → Project**, import the repository, and leave **Root Directory**
   at the repository root. Vercel reads the services from `vercel.json`; there
   is no framework preset to choose.
2. Set **Settings → General → Node.js Version** to 22.
3. Add these environment variables for Production and Preview. All services in
   the project share them:

   | Name                                | Value                                          |
   |-------------------------------------|------------------------------------------------|
   | `DATABASE_URL`                      | Supabase **transaction pooler** URL (port 6543) |
   | `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | Clerk publishable key                          |
   | `CLERK_SECRET_KEY`                  | Clerk secret key                               |
   | `CLERK_WEBHOOK_SECRET`              | Clerk webhook signing secret (after step 5)    |
   | `LOG_LEVEL`                         | `info`                                         |

   Do not set `API_URL`: the `web` service's binding injects it at runtime,
   pointing at the same deployment's `api` service, so preview deployments
   pair with their own API.
4. Deploy, then confirm `https://<host>/api/health` returns a JSON object with
   `status: "ok"` and that the home page lists the Portland community.
5. In Clerk, add the deployment URL to the allowed origins and create a user
   webhook to `https://<host>/api/users`. Store its signing secret as
   `CLERK_WEBHOOK_SECRET` and redeploy.

The API serves the same routes at `/` and under `/api`: Vercel forwards the
`/api` prefix unchanged, while local development and binding calls use the
bare paths. `apps/api/src/index.ts` remains the local Node entry point.

To check the build without deploying, run `npx vercel@latest build` in a clean
checkout after creating a placeholder `.vercel/project.json`; `vercel dev`
does not run build commands, so build the workspace packages first if you use
it.
