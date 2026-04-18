/**
 * Authenticated API client for use in server components and server actions.
 * Attaches the Clerk JWT to every request.
 */
import { auth } from '@clerk/nextjs/server'
import type { Community, Merchant, Product } from '@localmart/types'

const API_URL = process.env['NEXT_PUBLIC_API_URL'] ?? 'http://localhost:3001'

async function authFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const token = await auth().getToken()
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init?.headers,
    },
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`API ${res.status}: ${text}`)
  }
  return res.json() as Promise<T>
}

export const apiAuth = {
  merchants: {
    me: () => authFetch<Merchant>('/merchants/me'),
    apply: (body: Omit<Merchant, 'id' | 'userId' | 'status' | 'approvedBy' | 'approvedAt' | 'createdAt' | 'updatedAt'>) =>
      authFetch<Merchant>('/merchants', { method: 'POST', body: JSON.stringify(body) }),
  },
  products: {
    list: (merchantId: string) => authFetch<Product[]>(`/products?merchantId=${merchantId}`),
    create: (body: Omit<Product, 'id' | 'source' | 'externalId' | 'moderationStatus' | 'isPublished' | 'createdAt' | 'updatedAt' | 'lastSyncedAt'>) =>
      authFetch<Product>('/products', { method: 'POST', body: JSON.stringify(body) }),
    update: (id: string, body: Partial<Pick<Product, 'name' | 'description' | 'price' | 'stockQuantity' | 'images' | 'categories'>>) =>
      authFetch<Product>(`/products/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
    delete: (id: string) =>
      authFetch<{ success: boolean }>(`/products/${id}`, { method: 'DELETE' }),
    publish: (id: string) =>
      authFetch<Product>(`/products/${id}/publish`, { method: 'POST' }),
  },
}
