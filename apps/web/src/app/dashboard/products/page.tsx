import { redirect } from 'next/navigation'
import Link from 'next/link'
import { apiAuth } from '@/lib/api-auth'
import { ProductActions } from './product-actions'

function formatPrice(cents: number) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(cents / 100)
}

const moderationBadge: Record<string, string> = {
  pending: 'bg-yellow-50 text-yellow-700',
  clean:   'bg-emerald-50 text-emerald-700',
  flagged: 'bg-red-50 text-red-700',
  held:    'bg-stone-100 text-stone-500',
}

export default async function ProductsPage() {
  let merchant
  try {
    merchant = await apiAuth.merchants.me()
  } catch {
    redirect('/dashboard')
  }

  const products = await apiAuth.products.list(merchant.id).catch(() => [])

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-stone-900">Products</h1>
        {merchant.status === 'approved' && (
          <Link
            href="/dashboard/products/new"
            className="rounded-md bg-emerald-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-emerald-700"
          >
            + Add product
          </Link>
        )}
      </div>

      {products.length === 0 ? (
        <p className="text-stone-400">No products yet.</p>
      ) : (
        <div className="divide-y divide-stone-100 rounded-xl border border-stone-200 bg-white">
          {products.map((p) => (
            <div key={p.id} className="flex items-center justify-between px-5 py-4">
              <div className="min-w-0">
                <p className="truncate font-medium text-stone-800">{p.name}</p>
                <div className="mt-1 flex items-center gap-3 text-sm text-stone-400">
                  <span>{formatPrice(p.price)}</span>
                  <span>{p.stockQuantity} in stock</span>
                  <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${moderationBadge[p.moderationStatus] ?? ''}`}>
                    {p.moderationStatus}
                  </span>
                  {p.isPublished && (
                    <span className="rounded-full bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700">
                      Published
                    </span>
                  )}
                </div>
              </div>
              <ProductActions product={p} />
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
