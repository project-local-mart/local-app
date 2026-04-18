# Localmart — Prioritized Build Roadmap

Infrastructure target: **AWS** | IaC: **Terraform** | Secrets: **HashiCorp Vault**

Items are ordered within each tier by dependency — complete them roughly top to bottom.
A later tier should not start until the tier above it is substantially complete.

---

## Tier 0 — Foundation (nothing works without these)

These are hard blockers. Nothing in Tier 1 can be built or tested until these are done.

### AWS Account & Terraform Bootstrap
- [ ] Create AWS Organization with separate accounts: `prod`, `staging`, `dev`, `shared-services`
- [ ] Enable AWS SSO (IAM Identity Center) with MFA enforced for all humans
- [ ] Create Terraform S3 remote state bucket + DynamoDB lock table in `shared-services`
- [ ] Write root Terraform module with provider config, backend config, and workspace strategy
- [ ] Create base IAM roles: `TerraformDeployer`, `Developer`, `ReadOnly`, `CI`
- [ ] Enable AWS CloudTrail, Config, and GuardDuty across all accounts

### Networking (VPC)
- [ ] Design IP space: non-overlapping CIDRs for prod/staging/dev VPCs
- [ ] Terraform module: VPC with 3 public + 3 private + 3 isolated (DB) subnets across 3 AZs
- [ ] NAT Gateway per AZ in prod; single NAT in staging/dev
- [ ] VPC endpoints for S3, ECR, Secrets Manager, and SSM (eliminate NAT traffic for AWS services)
- [ ] Security group strategy document + Terraform security group modules
- [ ] Route 53 private hosted zone (`localmart.internal`) for service discovery
- [ ] AWS Certificate Manager wildcard cert for `*.localmart.app` (and `*.localmart.internal`)

### HashiCorp Vault
- [ ] Deploy Vault on ECS Fargate (HA, 3 tasks) in private subnets
- [ ] Configure Vault auto-unseal with AWS KMS
- [ ] Enable audit logging to CloudWatch Logs
- [ ] Configure AWS auth method (EC2 + IAM roles for ECS tasks)
- [ ] Enable **Transit secrets engine** for application-level encryption (POS tokens, sensitive fields)
- [ ] Enable **Database secrets engine** with dynamic Postgres credentials (short-lived, auto-rotated)
- [ ] Enable **AWS secrets engine** for short-lived IAM credentials
- [ ] Write Vault policies per service (`api`, `worker`, `migration-runner`)
- [ ] Store static secrets (Clerk keys, POS app credentials, OpenAI key) in KV v2
- [ ] Document Vault unsealing runbook

### Database
- [ ] Terraform: RDS Aurora PostgreSQL 16 (compatible) cluster — 1 writer + 1 reader per AZ in prod
- [ ] Enable PostGIS extension on Aurora (verify version compatibility; may require custom parameter group)
- [ ] Terraform: subnet group, parameter group, security group (isolated subnets, API SG only)
- [ ] Enable RDS Proxy for connection pooling (ECS tasks → RDS Proxy → Aurora)
- [ ] Enable automated backups (7-day retention dev, 35-day prod) + point-in-time recovery
- [ ] Enable RDS encryption at rest with customer-managed KMS key
- [ ] Wire Drizzle migrations into a one-off ECS task (`migration-runner`) that runs on each deploy
- [ ] Finalize schema: add indexes for all foreign keys and common query patterns
- [ ] Add `updated_at` trigger function in Postgres (auto-update on row change)
- [ ] Row-level security (RLS) design: all tenant tables filterable by `community_id`

### Auth
- [ ] Provision Clerk application (prod + dev instances)
- [ ] Configure Clerk JWT template to include `role` and `communityId` claims
- [ ] Implement Clerk webhook handler in API (`/webhooks/clerk`) for user sync to DB
- [ ] Implement auth middleware in Hono: verify Clerk JWT, attach user context to request
- [ ] Define role-based access control (RBAC) matrix: which roles can call which routes
- [ ] Add `users` table to DB schema (mirrors Clerk user, stores `role`, `communityId`)

### CI/CD Pipeline
- [ ] Add `pnpm-lock.yaml` to repo (run `pnpm install` and commit)
- [ ] GitHub Actions: build and push Docker image to ECR on merge to `main`
- [ ] GitHub Actions: run Terraform plan on PR, Terraform apply on merge to `main`
- [ ] GitHub Actions: run `migration-runner` ECS task after each API deploy
- [ ] GitHub Actions: separate workflows for `dev`, `staging`, `prod` environments
- [ ] Store all CI secrets in GitHub Actions via Vault dynamic credentials (not static keys)
- [ ] Enforce branch protection on `main`: require CI green + 1 review

---

## Tier 1 — Core API & Data Layer

The API must be able to serve authenticated, role-scoped requests before any frontend is useful.

### API Structure
- [ ] Establish Hono router structure: `/v1/communities`, `/v1/merchants`, `/v1/products`, `/v1/moderators`
- [ ] Add request validation middleware using Zod (validate all inputs at boundary)
- [ ] Add structured logging middleware (JSON to stdout, picked up by CloudWatch)
- [ ] Add request ID header (`X-Request-ID`) propagated through all logs
- [ ] Add rate limiting middleware (sliding window, per-IP and per-user)
- [ ] Global error handler: consistent `{ error, code, requestId }` response shape
- [ ] Health check endpoint already exists — add DB connectivity check to it

### Community Management
- [ ] `POST /v1/communities` — platform_admin only
- [ ] `GET /v1/communities` — public list
- [ ] `GET /v1/communities/:slug` — public detail
- [ ] `PATCH /v1/communities/:id` — platform_admin only
- [ ] Seed script for first community (used in local dev)

### Merchant Onboarding
- [ ] `POST /v1/merchants` — consumer applies (status: pending)
- [ ] `GET /v1/merchants` — moderator/admin list with status filter
- [ ] `GET /v1/merchants/:id` — merchant (own), moderator, admin
- [ ] `PATCH /v1/merchants/:id/approve` — moderator: approve → send welcome email
- [ ] `PATCH /v1/merchants/:id/reject` — moderator: reject → send notification
- [ ] `PATCH /v1/merchants/:id/suspend` — moderator/admin
- [ ] `PATCH /v1/merchants/:id` — merchant: update own profile
- [ ] Geocoding on merchant create/update (address → lat/lng via AWS Location Service or Nominatim)

### Product Management
- [ ] `POST /v1/merchants/:id/products` — merchant: create product (status: pending moderation)
- [ ] `GET /v1/merchants/:id/products` — merchant: own products
- [ ] `PATCH /v1/products/:id` — merchant: edit (resets moderationStatus to pending)
- [ ] `DELETE /v1/products/:id` — merchant: soft delete
- [ ] `PATCH /v1/products/:id/moderate` — moderator: set moderationStatus (clean/flagged/held)
- [ ] `GET /v1/products` — public: published + clean + approved merchant only; filter by communityId, category, search

### Moderator Management
- [ ] `POST /v1/communities/:id/moderators` — platform_admin: assign moderator
- [ ] `DELETE /v1/communities/:id/moderators/:userId` — platform_admin: remove
- [ ] `GET /v1/communities/:id/moderators` — admin only

---

## Tier 2 — Product Features

Build these once the API foundation is solid and deployable.

### Search (Meilisearch)
- [ ] Terraform: Meilisearch on ECS Fargate (single task; not HA — acceptable for search)
- [ ] Terraform: EFS volume for Meilisearch data persistence
- [ ] Indexing worker: sync approved + published products to Meilisearch on create/update/delete
- [ ] Configure Meilisearch index: searchable attributes, filterable attributes (`communityId`, `categories`, `merchantId`), sortable (`price`, `createdAt`)
- [ ] `GET /v1/search` — proxy to Meilisearch with community scoping enforced server-side
- [ ] Geo-search: filter products by distance from consumer's location using Meilisearch geo filtering

### POS Integrations
- [ ] `POST /v1/merchants/:id/pos/square/connect` — OAuth2 flow initiation
- [ ] `GET /v1/merchants/:id/pos/square/callback` — exchange code, store encrypted tokens via Vault Transit
- [ ] `POST /v1/merchants/:id/pos/square/sync` — manual sync trigger
- [ ] Scheduled sync worker: BullMQ job per connected merchant, runs every 15 min
- [ ] Repeat OAuth + sync pattern for Shopify and Clover
- [ ] Token refresh logic for each provider (pre-emptive refresh before expiry)
- [ ] `GET /v1/merchants/:id/pos` — list active connections
- [ ] `DELETE /v1/merchants/:id/pos/:connectionId` — revoke and delete

### Task Queue (BullMQ + Redis)
- [ ] Terraform: ElastiCache Redis 7 cluster (cluster mode disabled, 1 primary + 1 replica) in private subnets
- [ ] BullMQ worker ECS task (separate from API — scales independently)
- [ ] Queues: `pos-sync`, `product-moderation`, `email`, `search-index`
- [ ] BullMQ Board (read-only UI) behind Clerk-protected route for admin visibility
- [ ] Dead letter handling: failed jobs after 3 retries → alert + log

### Content Moderation
- [ ] On product create/update: enqueue `product-moderation` job
- [ ] Moderation worker: send product name + description + images to OpenAI moderation API
- [ ] Auto-approve clean results; flag for human review on uncertain/violating results
- [ ] `GET /v1/moderation/queue` — moderator: list products awaiting human review
- [ ] `PATCH /v1/moderation/:productId` — moderator: final decision

### Storage (Product Images)
- [ ] Terraform: S3 bucket (`localmart-product-images-{env}`) — private, versioning enabled, KMS encrypted
- [ ] S3 bucket policy: deny public access; only CloudFront OAC and API role may read
- [ ] `POST /v1/products/:id/images/upload-url` — API returns pre-signed S3 PUT URL (60s TTL)
- [ ] Client uploads directly to S3 using pre-signed URL (API never handles image bytes)
- [ ] Image processing Lambda: on S3 PUT event → resize to standard sizes (thumb 200px, medium 800px, large 1600px), write back to S3
- [ ] Store S3 keys (not full URLs) in `products.images` — compose URLs at read time

### CDN (CloudFront)
- [ ] Terraform: CloudFront distribution for `localmart.app` → ALB (web frontend)
- [ ] Terraform: CloudFront distribution for `api.localmart.app` → ALB (API) — cache only GET /v1/products
- [ ] Terraform: CloudFront distribution for `cdn.localmart.app` → S3 product images bucket via OAC
- [ ] Configure Cache-Control headers on product image responses (immutable, 1 year)
- [ ] CloudFront WAF ACL: AWS managed rules (OWASP top 10, known bad inputs, IP reputation list)
- [ ] CloudFront access logs → S3 → Athena for query-time analysis
- [ ] Configure custom error pages (403 → branded 404, 500 → branded error page)

### Email
- [ ] Terraform: SES domain identity + DKIM for `localmart.app`; request production sending limit
- [ ] Email worker: consume `email` queue, render templates, send via SES
- [ ] Templates: merchant welcome, merchant approved, merchant rejected, merchant suspended, moderator invitation

---

## Tier 3 — Frontend (Web)

Build UI after the API is stable enough to integrate against.

### Design System
- [ ] Choose component library: shadcn/ui (recommended — copy-paste, Tailwind-native, no runtime overhead)
- [ ] Define color tokens, typography scale, spacing scale in `tailwind.config.ts`
- [ ] Build base components: Button, Input, Select, Badge, Card, Modal, Toast, Table, Pagination
- [ ] Add Storybook for component development and documentation

### Consumer Frontend (`apps/web`)
- [ ] Install and configure Clerk for Next.js (`@clerk/nextjs`)
- [ ] Layout: header with community selector, search bar, nav; footer
- [ ] Home page: community landing with featured merchants and category browse
- [ ] Search results page: product grid with filters (category, price range, distance)
- [ ] Product detail page: images, description, price, stock, merchant info, map pin
- [ ] Merchant profile page: about, product listing, address + map
- [ ] Sign-up / sign-in pages (Clerk hosted UI or custom)
- [ ] Consumer account page: profile, saved merchants

### Merchant Dashboard (`apps/web` — separate route group `/dashboard`)
- [ ] Merchant onboarding wizard: business info → eligibility confirmation → submit for review
- [ ] Dashboard home: status banner (pending/approved/suspended), quick stats
- [ ] Product list: table with status badges, bulk publish/unpublish
- [ ] Product create/edit form: name, description, price, stock, images (upload widget), categories
- [ ] POS integrations page: connect Square / Shopify / Clover, view sync status, manual sync trigger
- [ ] Account settings: update business profile, contact info

### Moderator Dashboard (`apps/web` — separate route group `/mod`)
- [ ] Community overview: merchant count, pending applications, flagged products
- [ ] Merchant application queue: review, approve/reject with optional note
- [ ] Merchant list: filter by status, view profile, suspend
- [ ] Product moderation queue: review flagged products, approve/hold/reject

### Platform Admin (`apps/web` — separate route group `/admin`)
- [ ] Global community list: create, view, assign moderators
- [ ] Global merchant list: cross-community view, override any status
- [ ] User list: view roles, manually assign platform_admin or moderator role

---

## Tier 4 — Security Hardening & Observability

Do this before any public launch, in parallel with late Tier 3 work.

### Security
- [ ] Dependency scanning: add `pnpm audit` step to CI; block on high/critical
- [ ] SAST: add CodeQL to GitHub Actions
- [ ] Container image scanning: ECR scan on push; block deploy on critical CVEs
- [ ] Secrets detection: add `trufflehog` or `gitleaks` pre-commit hook and CI step
- [ ] API: add `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security` headers
- [ ] API: enforce HTTPS-only via ALB listener rules (redirect 80 → 443)
- [ ] Implement CSRF protection for all mutating endpoints
- [ ] Rotate all secrets (Clerk, POS credentials, Vault root token) before prod launch
- [ ] Conduct internal threat model review against OWASP Top 10
- [ ] Penetration test (manual or via automated tool like OWASP ZAP) before public launch

### Encryption
- [ ] All data in transit: TLS 1.2 minimum enforced at ALB and CloudFront
- [ ] All data at rest: KMS CMK encryption on RDS, S3, ElastiCache, EBS, CloudWatch Logs
- [ ] POS `accessToken` and `refreshToken`: encrypt/decrypt via Vault Transit engine before DB write/read
- [ ] KMS key rotation: enable annual automatic rotation on all CMKs
- [ ] Vault Transit key rotation policy for POS tokens (rotate every 90 days)

### Observability
- [ ] Structured JSON logs from API and workers → CloudWatch Logs
- [ ] CloudWatch Log Insights saved queries for common debugging patterns
- [ ] AWS X-Ray tracing on API (Hono middleware) and Lambda (image processor)
- [ ] CloudWatch dashboard: API p50/p95/p99 latency, error rate, queue depth, DB connections
- [ ] Alarms: API 5xx rate > 1%, DB CPU > 80%, Redis memory > 80%, queue depth > 1000
- [ ] Alarm destination: SNS → PagerDuty (or email for v1)
- [ ] Synthetic canary (CloudWatch Synthetics): ping `GET /health` and `GET /v1/products` every 1 min

### Backup & Recovery
- [ ] Document and test RDS point-in-time restore procedure
- [ ] S3 cross-region replication for product images bucket (prod only)
- [ ] Vault snapshot policy: automated daily snapshots to S3
- [ ] Define RTO / RPO targets and document recovery runbooks
- [ ] Run a full DR drill before public launch

---

## Tier 5 — Mobile (Merchant App)

Re-enable `apps/merchant` in `pnpm-workspace.yaml` when ready to start this tier.

### Expo Setup
- [ ] Re-enable `apps/merchant` in `pnpm-workspace.yaml`
- [ ] Configure Expo EAS Build for iOS and Android
- [ ] Set up Expo EAS Update for OTA updates
- [ ] Configure Expo EAS Submit for App Store and Google Play
- [ ] Add app signing credentials to Vault KV (do not store in repo or EAS secrets)

### Auth & API Integration
- [ ] Install Clerk Expo SDK, configure sign-in flow
- [ ] Create typed API client in `packages/types` (or a new `packages/api-client` package)
- [ ] Implement token refresh logic (Expo SecureStore for token persistence)

### Merchant App Features
- [ ] Home screen: dashboard summary (pending orders, product count, sync status)
- [ ] Product list: browse, quick stock edit, publish toggle
- [ ] Product create/edit: camera integration for images, barcode scanner for SKU/barcode
- [ ] POS connection: OAuth flow via in-app browser (Expo WebBrowser)
- [ ] Sync status screen: last sync time, manual trigger, error log
- [ ] Push notifications: Expo Notifications for moderation decisions and sync errors
- [ ] Account / settings screen

---

## Tier 6 — Scale & Optimization

Address these once the platform has real traffic.

- [ ] Aurora read replica for product listing queries (separate read vs write connection pool)
- [ ] CloudFront caching strategy review: increase cache TTLs for product images and static pages
- [ ] Meilisearch evaluation: consider managed Meilisearch Cloud or Typesense at scale
- [ ] BullMQ worker autoscaling: ECS service auto-scaling based on SQS queue depth approximation
- [ ] Database query analysis: run `EXPLAIN ANALYZE` on slow query log, add missing indexes
- [ ] Consider moving Meilisearch sync to DynamoDB Streams or Postgres logical replication for real-time
- [ ] Multi-region readiness: evaluate US-East + US-West active-passive for Aurora Global Database
- [ ] Cost review: Reserved Instances or Savings Plans for steady-state ECS and RDS workloads

---

## Dependency Graph (summary)

```
Tier 0 (AWS + Terraform + Vault + DB + Auth + CI)
  └── Tier 1 (API + Data Layer)
        └── Tier 2 (Search + POS + Queue + Storage + CDN)
              ├── Tier 3 (Web Frontend)
              └── Tier 4 (Security Hardening) ← run in parallel with Tier 3
                    └── Public Launch
                          └── Tier 5 (Mobile)
                                └── Tier 6 (Scale)
```

---

## Open decisions to resolve before Tier 2

| Decision | Options | Notes |
|----------|---------|-------|
| Product image storage | S3 + CloudFront vs keep Cloudflare R2 | `.env.example` has R2 vars; AWS-native is simpler on AWS infra |
| Geocoding provider | AWS Location Service vs Nominatim (OSM) | AWS Location is paid but avoids Google Maps dependency |
| Email provider | SES vs Postmark vs Resend | SES cheapest at scale; Postmark best deliverability for transactional |
| Meilisearch hosting | Self-hosted ECS vs Meilisearch Cloud | Self-hosted fine for v1; Cloud removes ops burden |
| API hosting | ECS Fargate vs App Runner vs Lambda | ECS recommended — persistent connections to DB and Redis |
