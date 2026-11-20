/**
 * Development seed script.
 * Inserts the minimum data needed to run the app locally.
 * Safe to run multiple times — uses ON CONFLICT DO NOTHING.
 *
 * Usage: pnpm db:seed  (from repo root)
 */

import postgres from 'postgres'
import { drizzle } from 'drizzle-orm/postgres-js'
import { communities, merchants, products, users } from './schema'

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
      businessName: 'Rose City Books',
      ownerName: 'Morgan Lee',
      email: 'merchant@localmart.dev',
      phone: '503-555-0100',
      address: '725 SE Grand Ave',
      city: 'Portland',
      state: 'OR',
      zip: '97214',
      lat: 45.5189,
      lng: -122.6604,
      status: 'approved',
      approvedBy: 'user_dev_admin',
      approvedAt: new Date(),
    })
    .onConflictDoNothing()

  // ── Published products for the public demo ───────────────────────────────
  await db
    .insert(products)
    .values([
      {
        id: 'product_dev_001',
        merchantId: 'merchant_dev_001',
        name: 'Pacific Northwest Field Guide',
        description: 'A pocket guide to the plants, birds, and trails of the Pacific Northwest.',
        price: 1895,
        stockQuantity: 12,
        sku: 'RCB-FIELD-001',
        images: [
          'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=900&q=80',
        ],
        categories: ['Books', 'Nature'],
        moderationStatus: 'clean',
        isPublished: true,
      },
      {
        id: 'product_dev_002',
        merchantId: 'merchant_dev_001',
        name: 'Local Authors Short Story Collection',
        description: 'New fiction from independent writers across Oregon.',
        price: 2400,
        stockQuantity: 8,
        sku: 'RCB-STORY-002',
        images: [
          'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=900&q=80',
        ],
        categories: ['Books', 'Fiction'],
        moderationStatus: 'clean',
        isPublished: true,
      },
      {
        id: 'product_dev_003',
        merchantId: 'merchant_dev_001',
        name: 'Letterpress Reading Journal',
        description: 'A locally printed journal for notes, quotes, and your next reading list.',
        price: 1600,
        stockQuantity: 20,
        sku: 'RCB-JOURNAL-003',
        images: [
          'https://images.unsplash.com/photo-1531346878377-a5be20888e57?auto=format&fit=crop&w=900&q=80',
        ],
        categories: ['Stationery', 'Gifts'],
        moderationStatus: 'clean',
        isPublished: true,
      },
    ])
    .onConflictDoNothing()

  console.log('Seed complete.')
  await client.end()
}

seed().catch((err) => {
  console.error('Seed failed:', err)
  process.exit(1)
})
