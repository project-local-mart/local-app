import Link from 'next/link'
import { notFound } from 'next/navigation'
import { api } from '@/lib/api'

export const revalidate = 60

interface Props {
  params: { id: string }
}

function formatPrice(cents: number) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(
    cents / 100
  )
}

export default async function MerchantPage({ params }: Props) {
  let merchant
  try {
    merchant = await api.merchants.get(params.id)
  } catch {
    notFound()
  }

  const products = await api.products.list(merchant.id).catch(() => [])

  return (
    <div>
      <div className="mb-8">
        <Link
          href={`/communities/${merchant.communityId}`}
          className="text-sm text-emerald-600 hover:underline"
        >
          ← Back to community
        </Link>
        <h1 className="mt-2 text-3xl font-bold text-stone-900">{merchant.businessName}</h1>
        <p className="mt-1 text-stone-500">
          {merchant.address}, {merchant.city}, {merchant.state} {merchant.zip}
        </p>
        <p className="text-sm text-stone-400">{merchant.phone} · {merchant.email}</p>
      </div>

      <section>
        <h2 className="mb-5 text-xl font-semibold text-stone-700">Products</h2>
        {products.length === 0 ? (
          <p className="text-stone-400">No products listed yet.</p>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {products.map((p) => (
              <div
                key={p.id}
                className="rounded-xl border border-stone-200 bg-white p-5 shadow-sm"
              >
                {p.images[0] && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={p.images[0]}
                    alt={p.name}
                    className="mb-3 h-40 w-full rounded-lg object-cover"
                  />
                )}
                <h3 className="font-semibold text-stone-800">{p.name}</h3>
                {p.description && (
                  <p className="mt-1 line-clamp-2 text-sm text-stone-500">{p.description}</p>
                )}
                <div className="mt-3 flex items-center justify-between">
                  <span className="text-lg font-bold text-emerald-700">
                    {formatPrice(p.price)}
                  </span>
                  <span className="text-xs text-stone-400">
                    {p.stockQuantity > 0 ? `${p.stockQuantity} in stock` : 'Out of stock'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
