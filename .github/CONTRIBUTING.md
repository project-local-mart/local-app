# Contributing to Localmart

Localmart is an open source, community-owned local retail marketplace. Our mission is to help independent local businesses connect with shoppers in their neighborhoods — without the middlemen, fees, and extraction dynamics of large commercial platforms. It is built by volunteers and maintained in the open.

We welcome contributions of all kinds: bug fixes, new features, documentation improvements, and community policy input.

## Development setup

**Prerequisites**

- [Node.js](https://nodejs.org) 20 or later
- [pnpm](https://pnpm.io) 9 or later (`npm install -g pnpm`)
- [Docker](https://www.docker.com) (for local services)

**Steps**

```bash
# 1. Clone the repository
git clone https://github.com/localmart/localmart.git
cd localmart

# 2. Install all dependencies
pnpm install

# 3. Set up your local environment
cp .env.example .env
# Edit .env and fill in any values you need for local development

# 4. Start infrastructure services (Postgres, Redis, Meilisearch)
docker-compose up -d

# 5. Run all apps in development mode
pnpm dev
```

After running `pnpm dev`, the following services will be available:

| Service          | URL                    |
|------------------|------------------------|
| Web (Next.js)    | http://localhost:3000  |
| API (Hono)       | http://localhost:3001  |
| Meilisearch      | http://localhost:7700  |

For the merchant mobile app, open a new terminal and run `pnpm dev` inside `apps/merchant/`, then use the Expo Go app on your device or an iOS/Android simulator.

## Branch naming

Use the following conventions for branch names:

- `feature/short-description` — new features
- `fix/short-description` — bug fixes
- `docs/short-description` — documentation changes

Examples: `feature/merchant-search`, `fix/product-sync-race-condition`, `docs/add-adr-003`

## Pull request guidelines

- **One feature or fix per PR.** Keep PRs focused so they are easy to review.
- **Describe what and why.** Fill out the PR template fully. Reviewers need to understand the motivation behind the change, not just what files changed.
- **All CI checks must pass** before a PR can be merged (typecheck, lint, build).
- **Link related issues** using GitHub keywords (`Closes #123`, `Fixes #456`).

## Contributor License Agreement

All contributors must agree to the [Contributor License Agreement](../CLA.md) before their code can be merged. By opening a pull request, you confirm that you have read and agree to its terms.

## License

Localmart is licensed under the [GNU Affero General Public License v3.0 (AGPL-3.0)](../LICENSE). Any contributions you make will be licensed under the same terms.
