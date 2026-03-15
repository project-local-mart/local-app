import {
  pgTable,
  text,
  timestamp,
  integer,
  boolean,
  doublePrecision,
  pgEnum,
} from 'drizzle-orm/pg-core'

// Enums
export const userRoleEnum = pgEnum('user_role', [
  'platform_admin',
  'moderator',
  'merchant',
  'consumer',
])

export const merchantStatusEnum = pgEnum('merchant_status', [
  'pending',
  'approved',
  'suspended',
  'rejected',
])

export const productSourceEnum = pgEnum('product_source', [
  'manual',
  'square',
  'shopify',
  'clover',
  'csv',
])

export const moderationStatusEnum = pgEnum('moderation_status', [
  'pending',
  'clean',
  'flagged',
  'held',
])

export const posProviderEnum = pgEnum('pos_provider', [
  'square',
  'shopify',
  'clover',
])

// Communities table
export const communities = pgTable('communities', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  slug: text('slug').notNull().unique(),
  zipCodes: text('zip_codes').array().notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
})

// Moderators table
export const moderators = pgTable('moderators', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull(),
  communityId: text('community_id')
    .notNull()
    .references(() => communities.id),
  createdAt: timestamp('created_at').notNull().defaultNow(),
})

// Merchants table
export const merchants = pgTable('merchants', {
  id: text('id').primaryKey(),
  communityId: text('community_id')
    .notNull()
    .references(() => communities.id),
  businessName: text('business_name').notNull(),
  ownerName: text('owner_name').notNull(),
  email: text('email').notNull(),
  phone: text('phone').notNull(),
  address: text('address').notNull(),
  city: text('city').notNull(),
  state: text('state').notNull(),
  zip: text('zip').notNull(),
  lat: doublePrecision('lat').notNull(),
  lng: doublePrecision('lng').notNull(),
  status: merchantStatusEnum('status').notNull().default('pending'),
  approvedBy: text('approved_by'),
  approvedAt: timestamp('approved_at'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
})

// Products table
export const products = pgTable('products', {
  id: text('id').primaryKey(),
  merchantId: text('merchant_id')
    .notNull()
    .references(() => merchants.id),
  name: text('name').notNull(),
  description: text('description'),
  price: integer('price').notNull(),
  currency: text('currency').notNull().default('USD'),
  stockQuantity: integer('stock_quantity').notNull(),
  sku: text('sku'),
  barcode: text('barcode'),
  images: text('images').array().notNull().default([]),
  categories: text('categories').array().notNull().default([]),
  source: productSourceEnum('source').notNull().default('manual'),
  externalId: text('external_id'),
  moderationStatus: moderationStatusEnum('moderation_status')
    .notNull()
    .default('pending'),
  isPublished: boolean('is_published').notNull().default(false),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
  lastSyncedAt: timestamp('last_synced_at'),
})

// POS connections table
export const posConnections = pgTable('pos_connections', {
  id: text('id').primaryKey(),
  merchantId: text('merchant_id')
    .notNull()
    .references(() => merchants.id),
  provider: posProviderEnum('provider').notNull(),
  externalMerchantId: text('external_merchant_id').notNull(),
  accessToken: text('access_token').notNull(),
  refreshToken: text('refresh_token'),
  expiresAt: timestamp('expires_at'),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
})
