import { notFound, redirect } from 'next/navigation'
import { apiAuth } from '@/lib/api-auth'
import { updateProduct } from '../../../actions'

interface Props {
  params: { id: string }
}

export default async function EditProductPage({ params }: Props) {
  let merchant
  try {
    merchant = await apiAuth.merchants.me()
  } catch {
    redirect('/dashboard')
  }

  const products = await apiAuth.products.list(merchant.id).catch(() => [])
  const product = products.find((p) => p.id === params.id)
  if (!product) notFound()

  const action = updateProduct.bind(null, product.id)

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold text-stone-900">Edit product</h1>
      <form action={action} className="space-y-4">
        <div>
          <label className="mb-1 block text-sm font-medium text-stone-700">Name *</label>
          <input
            name="name"
            required
            defaultValue={product.name}
            className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
          />
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium text-stone-700">Description</label>
          <textarea
            name="description"
            rows={3}
            defaultValue={product.description ?? ''}
            className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-stone-700">Price (USD) *</label>
            <input
              name="price"
              type="number"
              step="0.01"
              min="0.01"
              required
              defaultValue={(product.price / 100).toFixed(2)}
              className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-stone-700">Stock qty *</label>
            <input
              name="stockQuantity"
              type="number"
              min="0"
              required
              defaultValue={product.stockQuantity}
              className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
            />
          </div>
        </div>

        <div className="flex gap-3 pt-2">
          <button
            type="submit"
            className="rounded-md bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700"
          >
            Save changes
          </button>
          <a href="/dashboard/products" className="rounded-md px-4 py-2 text-sm text-stone-500 hover:text-stone-800">
            Cancel
          </a>
        </div>
      </form>
    </div>
  )
}
