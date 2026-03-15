// User roles
export type UserRole = 'platform_admin' | 'moderator' | 'merchant' | 'consumer'

// Community — a named geographic area covering one or more zip codes
export interface Community {
  id: string
  name: string
  slug: string
  zipCodes: string[]
  createdAt: Date
  updatedAt: Date
}

// Moderator — a user scoped to a single community
export interface Moderator {
  id: string
  userId: string
  communityId: string
  createdAt: Date
}

// Merchant — a local business approved within a community
export interface Merchant {
  id: string
  communityId: string
  businessName: string
  ownerName: string
  email: string
  phone: string
  address: string
  city: string
  state: string
  zip: string
  lat: number
  lng: number
  status: 'pending' | 'approved' | 'suspended' | 'rejected'
  approvedBy: string | null
  approvedAt: Date | null
  createdAt: Date
  updatedAt: Date
}

// Product — a listing created by a merchant
export interface Product {
  id: string
  merchantId: string
  name: string
  description: string | null
  price: number              // stored in cents
  currency: string           // default 'USD'
  stockQuantity: number
  sku: string | null
  barcode: string | null
  images: string[]
  categories: string[]
  source: 'manual' | 'square' | 'shopify' | 'clover' | 'csv'
  externalId: string | null
  moderationStatus: 'pending' | 'clean' | 'flagged' | 'held'
  isPublished: boolean
  createdAt: Date
  updatedAt: Date
  lastSyncedAt: Date | null
}

// POS connection — a linked POS account for a merchant
export interface POSConnection {
  id: string
  merchantId: string
  provider: 'square' | 'shopify' | 'clover'
  externalMerchantId: string
  accessToken: string        // encrypted at rest
  refreshToken: string | null
  expiresAt: Date | null
  isActive: boolean
  createdAt: Date
  updatedAt: Date
}
