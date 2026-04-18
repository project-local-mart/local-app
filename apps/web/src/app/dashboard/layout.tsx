import { redirect } from 'next/navigation'
import { auth } from '@clerk/nextjs/server'
import Link from 'next/link'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { userId } = auth()
  if (!userId) redirect('/sign-in')

  return (
    <div className="flex gap-8">
      <aside className="w-48 shrink-0">
        <nav className="flex flex-col gap-1 text-sm">
          <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-stone-400">
            Merchant
          </p>
          <Link
            href="/dashboard"
            className="rounded-md px-3 py-2 text-stone-600 hover:bg-stone-100 hover:text-stone-900"
          >
            Overview
          </Link>
          <Link
            href="/dashboard/products"
            className="rounded-md px-3 py-2 text-stone-600 hover:bg-stone-100 hover:text-stone-900"
          >
            Products
          </Link>
        </nav>
      </aside>
      <div className="flex-1 min-w-0">{children}</div>
    </div>
  )
}
