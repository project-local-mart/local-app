import Link from 'next/link'
import { notFound } from 'next/navigation'
import { api } from '@/lib/api'

export const revalidate = 60

interface Props {
  params: { slug: string }
}

export default async function CommunityPage({ params }: Props) {
  let community
  try {
    community = await api.communities.get(params.slug)
  } catch {
    notFound()
  }

  const merchants = await api.merchants.list(community.id).catch(() => [])

  return (
    <div>
      <div className="mb-8">
        <Link href="/" className="text-sm text-emerald-600 hover:underline">
          ← All communities
        </Link>
        <h1 className="mt-2 text-3xl font-bold text-stone-900">{community.name}</h1>
        <p className="mt-1 text-sm text-stone-400">
          Serving {community.zipCodes.join(', ')}
        </p>
      </div>

      <section>
        <h2 className="mb-5 text-xl font-semibold text-stone-700">Local Businesses</h2>
        {merchants.length === 0 ? (
          <p className="text-stone-400">No merchants yet in this community.</p>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {merchants.map((m) => (
              <Link
                key={m.id}
                href={`/merchants/${m.id}`}
                className="rounded-xl border border-stone-200 bg-white p-5 shadow-sm transition hover:shadow-md"
              >
                <h3 className="font-semibold text-stone-800">{m.businessName}</h3>
                <p className="mt-1 text-sm text-stone-500">{m.address}, {m.city}</p>
                <span className="mt-3 inline-block rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-700">
                  {m.status}
                </span>
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
