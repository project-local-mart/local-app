# ADR 001 — Technology stack

**Date:** 2026-03-14
**Status:** Accepted

## Context

Localmart requires a consumer web frontend, a merchant mobile app, and a backend API. The project is open source and community-funded, so developer accessibility and contributor onboarding speed are priorities alongside technical correctness.

## Decision

We will use a TypeScript monorepo with the following stack:

- Consumer frontend: Next.js 14 (App Router) on Vercel
- Merchant mobile app: React Native with Expo SDK 51
- Backend API: Hono.js on Node.js
- Database: PostgreSQL 16 with PostGIS
- ORM: Drizzle
- Search: Meilisearch
- Task queue: BullMQ with Redis
- Monorepo tooling: Turborepo with pnpm workspaces

## Rationale

TypeScript across all layers allows shared types between frontend, mobile, and backend, reducing drift and bugs at boundaries. The JavaScript ecosystem has a significantly larger contributor pool than alternatives, which is important for an open source project. Vercel and Expo provide excellent developer experience for iteration speed in early stages. Hono is lightweight, fast, and framework-agnostic.

## Consequences

Node.js has a higher memory footprint than Go, which was an earlier consideration. This is acceptable for v1 given the contributor accessibility benefits. Self-hosted node deployments will use Docker to keep the deployment story manageable.
