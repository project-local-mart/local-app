# @localmart/db

Drizzle ORM schema and migrations for the Localmart database (PostgreSQL 16 with PostGIS).

## Prerequisites

- PostgreSQL 16 running (see root `docker-compose.yml`)
- `DATABASE_URL` set in your environment (copy `.env.example` → `.env`)

## Running migrations

**1. Generate migration files from the schema**

```bash
pnpm db:generate
```

This reads `src/schema.ts` and writes SQL migration files into the `drizzle/` directory.

**2. Apply migrations to the database**

```bash
pnpm db:migrate
```

This runs any pending migrations against the database specified by `DATABASE_URL`.

## Adding or changing the schema

1. Edit `src/schema.ts`
2. Run `pnpm db:generate` to generate a new migration
3. Commit both the schema change and the generated migration file
4. Run `pnpm db:migrate` to apply it locally

Never edit generated migration files by hand. If you need to undo a change, create a new migration that reverses it.
