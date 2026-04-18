'use client'

import Link from 'next/link'
import { useTransition } from 'react'
import type { Product } from '@localmart/types'
import { deleteProduct, publishProduct } from '../actions'

export function ProductActions({ product }: { product: Product }) {
  const [isPending, startTransition] = useTransition()

  return (
    <div className="flex shrink-0 items-center gap-2 pl-4 text-sm">
      <Link
        href={`/dashboard/products/${product.id}/edit`}
        className="text-stone-500 hover:text-stone-800"
      >
        Edit
      </Link>
      {!product.isPublished && product.moderationStatus === 'clean' && (
        <button
          onClick={() => startTransition(() => publishProduct(product.id))}
          disabled={isPending}
          className="text-emerald-600 hover:text-emerald-800 disabled:opacity-50"
        >
          Publish
        </button>
      )}
      <button
        onClick={() => {
          if (confirm(`Delete "${product.name}"?`)) {
            startTransition(() => deleteProduct(product.id))
          }
        }}
        disabled={isPending}
        className="text-red-400 hover:text-red-600 disabled:opacity-50"
      >
        Delete
      </button>
    </div>
  )
}
