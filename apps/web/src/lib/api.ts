import type { Community, Merchant, Product } from '@localmart/types'

const API_URL = process.env['NEXT_PUBLIC_API_URL'] ?? 'http://localhost:3001'

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...init?.headers },
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`API ${res.status}: ${text}`)
  }
  return res.json() as Promise<T>
}

export const api = {
  communities: {
    list: () => apiFetch<Community[]>('/communities'),
    get: (slug: string) => apiFetch<Community>(`/communities/${slug}`),
  },
  merchants: {
    list: (communityId?: string) =>
      apiFetch<Merchant[]>(
        communityId ? `/merchants?communityId=${communityId}` : '/merchants'
      ),
    get: (id: string) => apiFetch<Merchant>(`/merchants/${id}`),
  },
  products: {
    list: (merchantId?: string) =>
      apiFetch<Product[]>(
        merchantId ? `/products?merchantId=${merchantId}` : '/products'
      ),
    get: (id: string) => apiFetch<Product>(`/products/${id}`),
  },
}
