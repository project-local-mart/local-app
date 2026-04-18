# Localmart — the community-owned local retail marketplace

Localmart is an open source platform that connects independent local businesses with shoppers in their own neighborhoods. It is built and governed by the communities it serves — not by investors, advertisers, or platform operators extracting value from local commerce.

The platform exists because local retail deserves better infrastructure. Small businesses today either rely on foot traffic alone or hand over 15–30% of revenue to national marketplaces that have no stake in their community's success. Localmart gives each community its own curated storefront, moderated by local volunteers who know which businesses are genuinely independent and locally owned. Merchants keep their inventory in sync through direct POS integrations and pay nothing for discovery.

> **🚧 Early development — not yet accepting merchant applications**

---

## Features (v1 scope)

- **Consumer product search and discovery by neighborhood** — shoppers browse products from verified local merchants in their community
- **Merchant product listing (manual and POS import)** — merchants list products by hand or import directly from their point-of-sale system
- **Community moderation by local volunteers** — each community has moderators who review merchant applications and flag policy violations
- **Square, Shopify, and Clover inventory sync** — real-time or scheduled inventory sync keeps product listings accurate without manual effort

---

## Tech stack

| Layer              | Technology                          |
|--------------------|-------------------------------------|
| Consumer frontend  | Next.js 14 (App Router), Tailwind   |
| Merchant app       | React Native, Expo SDK 51 *(planned)*|
| Backend API        | Hono.js on Node.js                  |
| Database           | PostgreSQL 16 with PostGIS          |
| ORM                | Drizzle                             |
| Search             | Meilisearch                         |
| Task queue         | BullMQ + Redis                      |
| Monorepo tooling   | Turborepo + pnpm workspaces         |

---

## Getting started

**Prerequisites**

- [Node.js](https://nodejs.org) 20 or later
- [pnpm](https://pnpm.io) 9 or later
- [Docker](https://www.docker.com)

**Setup**

```bash
git clone https://github.com/localmart/localmart.git
cd localmart
pnpm install
cp .env.example .env
docker-compose up -d
pnpm dev
```

Once running:

| Service        | URL                   |
|----------------|-----------------------|
| Web frontend   | http://localhost:3000 |
| API            | http://localhost:3001 |
| Meilisearch    | http://localhost:7700 |

---

## Project structure

```
localmart/
├── apps/
│   ├── web/          # Next.js 14 consumer frontend
│   ├── merchant/     # Expo React Native merchant app (planned)
│   └── api/          # Hono.js backend API
├── packages/
│   ├── types/        # Shared TypeScript domain types
│   ├── db/           # Drizzle ORM schema and migrations
│   └── config/       # Shared ESLint and TypeScript configs
├── docs/
│   ├── decisions/    # Architecture Decision Records (ADRs)
│   └── policies/     # Community policy documents
└── .github/          # CI workflows, PR template, contributing guide
```

---

## Contributing

See [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) for setup instructions, branch naming conventions, and PR guidelines.

All contributors must agree to the [Contributor License Agreement](CLA.md).

---

## License

Localmart is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). We chose this license intentionally — this platform exists to serve communities, not to be commercialized by third parties. AGPL ensures that any improvements to the codebase remain open and available to the communities that depend on it. See [LICENSE](LICENSE) for the full license text.

---

## Acknowledgments

Localmart stands on the shoulders of the shop local movement and the decades of advocacy by organizations like [Main Street America](https://www.mainstreet.org). Independent retailers are the connective tissue of healthy communities. This project is dedicated to giving them better tools.
