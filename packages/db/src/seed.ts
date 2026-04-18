/**
 * Development seed script.
 * Inserts the minimum data needed to run the app locally.
 * Safe to run multiple times — uses ON CONFLICT DO NOTHING.
 *
 * Usage: pnpm db:seed  (from repo root)
 */

import postgres from 'postgres'
import { drizzle } from 'drizzle-orm/postgres-js'
import { communities, merchants, users } from './schema'

const DATABASE_URL =
  process.env['DATABASE_URL'] ??
  'postgresql://localmart:localmart_dev_password@localhost:5432/localmart_dev'

const client = postgres(DATABASE_URL)
const db = drizzle(client)

async function seed() {
  console.log('Seeding development database...')

  // ── Community ──────────────────────────────────────────────────────────────
  await db
    .insert(communities)
    .values({
      id: 'community_dev_portland',
      name: 'Portland',
      slug: 'portland',
      zipCodes: ['97201', '97202', '97203', '97204', '97205'],
    })
    .onConflictDoNothing()

  // ── Platform admin user ────────────────────────────────────────────────────
  await db
    .insert(users)
    .values({
      id: 'user_dev_admin',
      clerkId: 'user_dev_admin',
      email: 'admin@localmart.dev',
      role: 'platform_admin',
    })
    .onConflictDoNothing()

  // ── Test merchant ──────────────────────────────────────────────────────────
  await db
    .insert(merchants)
    .values({
      id: 'merchant_dev_001',
      communityId: 'community_dev_portland',
      businessName: 'Powell Books Dev Store',
      ownerName: 'Dev Owner',
      email: 'merchant@localmart.dev',
      phone: '503-555-0100',
      address: '1005 W Burnside St',
      city: 'Portland',
      state: 'OR',
      zip: '97209',
      lat: 45.5231,
      lng: -122.6815,
      status: 'approved',
      approvedBy: 'user_dev_admin',
      approvedAt: new Date(),
    })
    .onConflictDoNothing()

  console.log('Seed complete.')
  await client.end()
}

seed().catch((err) => {
  console.error('Seed failed:', err)
  process.exit(1)
})
