import Link from 'next/link'
import { api } from '@/lib/api'
import type { Community } from '@localmart/types'

export const revalidate = 60

export default async function HomePage() {
  let communities: Community[] = []
  try {
    communities = await api.communities.list()
  } catch {
    // API may be unavailable during build
  }

  return (
    <div>
      <section className="py-12 text-center">
        <h1 className="text-4xl font-bold tracking-tight text-stone-900">
          Shop local, support your community
        </h1>
        <p className="mt-3 text-lg text-stone-500">
          Discover independent businesses in your neighborhood.
        </p>
      </section>

      <section>
        <h2 className="mb-6 text-xl font-semibold text-stone-700">Communities</h2>
        {communities.length === 0 ? (
          <p className="text-stone-400">No communities yet.</p>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {communities.map((c) => (
              <Link
                key={c.id}
                href={`/communities/${c.slug}`}
                className="rounded-xl border border-stone-200 bg-white p-5 shadow-sm transition hover:shadow-md"
              >
                <h3 className="text-lg font-semibold text-stone-800">{c.name}</h3>
                <p className="mt-1 text-sm text-stone-400">
                  {c.zipCodes.length} zip code{c.zipCodes.length !== 1 ? 's' : ''}
                </p>
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
