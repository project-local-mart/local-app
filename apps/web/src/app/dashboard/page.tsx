import { apiAuth } from '@/lib/api-auth'
import Link from 'next/link'

interface Props {
  searchParams: { applied?: string }
}

const statusLabel: Record<string, { label: string; color: string }> = {
  pending:   { label: 'Pending review',  color: 'bg-yellow-50 text-yellow-700' },
  approved:  { label: 'Approved',        color: 'bg-emerald-50 text-emerald-700' },
  suspended: { label: 'Suspended',       color: 'bg-red-50 text-red-700' },
  rejected:  { label: 'Rejected',        color: 'bg-stone-100 text-stone-500' },
}

export default async function DashboardPage({ searchParams }: Props) {
  let merchant
  try {
    merchant = await apiAuth.merchants.me()
  } catch {
    // No merchant record — show apply prompt
  }

  if (!merchant) {
    return (
      <div className="rounded-xl border border-stone-200 bg-white p-8 text-center">
        <h2 className="text-xl font-semibold text-stone-800">You don&apos;t have a merchant account yet</h2>
        <p className="mt-2 text-stone-500">Apply to list your business on Localmart.</p>
        <Link
          href="/dashboard/apply"
          className="mt-4 inline-block rounded-md bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700"
        >
          Apply now
        </Link>
      </div>
    )
  }

  const { label, color } = statusLabel[merchant.status] ?? statusLabel['pending']!

  return (
    <div>
      <div className="mb-6 flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-stone-900">{merchant.businessName}</h1>
          <p className="text-stone-500">{merchant.address}, {merchant.city}, {merchant.state}</p>
        </div>
        <span className={`rounded-full px-3 py-1 text-sm font-medium ${color}`}>{label}</span>
      </div>

      {searchParams.applied === '1' && (
        <div className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
          Application submitted! We&apos;ll review it within 2–3 business days.
        </div>
      )}

      {merchant.status === 'pending' && (
        <div className="mb-6 rounded-lg border border-yellow-200 bg-yellow-50 px-4 py-3 text-sm text-yellow-800">
          Your application is under review. You&apos;ll be notified once approved.
        </div>
      )}

      {merchant.status === 'approved' && (
        <div className="grid gap-4 sm:grid-cols-2">
          <Link
            href="/dashboard/products/new"
            className="rounded-xl border border-emerald-200 bg-emerald-50 p-5 hover:bg-emerald-100"
          >
            <p className="font-semibold text-emerald-800">+ Add product</p>
            <p className="mt-1 text-sm text-emerald-600">List a new item for sale</p>
          </Link>
          <Link
            href="/dashboard/products"
            className="rounded-xl border border-stone-200 bg-white p-5 hover:bg-stone-50"
          >
            <p className="font-semibold text-stone-800">Manage products</p>
            <p className="mt-1 text-sm text-stone-500">Edit, publish, or remove listings</p>
          </Link>
        </div>
      )}
    </div>
  )
}
