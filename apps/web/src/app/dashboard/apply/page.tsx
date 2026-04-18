import { redirect } from 'next/navigation'
import { api } from '@/lib/api'
import { apiAuth } from '@/lib/api-auth'
import { applyAsMerchant } from '../actions'

export default async function ApplyPage() {
  // Redirect away if merchant record already exists
  try {
    await apiAuth.merchants.me()
    redirect('/dashboard')
  } catch {
    // No merchant yet — show the form
  }

  const communities = await api.communities.list().catch(() => [])

  return (
    <div className="max-w-xl">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-stone-900">Apply to sell on Localmart</h1>
        <p className="mt-2 text-stone-500">
          Fill in your business details. Your application will be reviewed by a community
          moderator within 2–3 business days.
        </p>
      </div>

      <form action={applyAsMerchant} className="space-y-5">
        {/* Community */}
        <div>
          <label className="mb-1 block text-sm font-medium text-stone-700">
            Community *
          </label>
          {communities.length === 0 ? (
            <p className="text-sm text-red-500">
              No communities are available yet. Please check back later.
            </p>
          ) : (
            <select
              name="communityId"
              required
              className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
            >
              <option value="">Select a community…</option>
              {communities.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          )}
        </div>

        {/* Business info */}
        <fieldset className="space-y-4 rounded-lg border border-stone-200 p-4">
          <legend className="px-1 text-sm font-semibold text-stone-600">Business</legend>

          <div>
            <label className="mb-1 block text-sm font-medium text-stone-700">
              Business name *
            </label>
            <input
              name="businessName"
              required
              className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
            />
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-stone-700">
              Owner / contact name *
            </label>
            <input
              name="ownerName"
              required
              className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-stone-700">
                Business email *
              </label>
              <input
                name="email"
                type="email"
                required
                className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-stone-700">
                Phone *
              </label>
              <input
                name="phone"
                type="tel"
                required
                placeholder="503-555-0100"
                className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
              />
            </div>
          </div>
        </fieldset>

        {/* Address */}
        <fieldset className="space-y-4 rounded-lg border border-stone-200 p-4">
          <legend className="px-1 text-sm font-semibold text-stone-600">Location</legend>

          <div>
            <label className="mb-1 block text-sm font-medium text-stone-700">
              Street address *
            </label>
            <input
              name="address"
              required
              className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-6 gap-3">
            <div className="col-span-3">
              <label className="mb-1 block text-sm font-medium text-stone-700">City *</label>
              <input
                name="city"
                required
                className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div className="col-span-1">
              <label className="mb-1 block text-sm font-medium text-stone-700">State *</label>
              <input
                name="state"
                required
                maxLength={2}
                placeholder="OR"
                className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm uppercase focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div className="col-span-2">
              <label className="mb-1 block text-sm font-medium text-stone-700">ZIP *</label>
              <input
                name="zip"
                required
                maxLength={5}
                pattern="\d{5}"
                placeholder="97201"
                className="w-full rounded-md border border-stone-300 px-3 py-2 text-sm focus:border-emerald-500 focus:outline-none"
              />
            </div>
          </div>

          {/* Lat/lng — hidden for now; will be geocoded automatically later */}
          <input type="hidden" name="lat" value="0" />
          <input type="hidden" name="lng" value="0" />
        </fieldset>

        <div className="flex items-center gap-3 pt-1">
          <button
            type="submit"
            className="rounded-md bg-emerald-600 px-5 py-2 text-sm font-medium text-white hover:bg-emerald-700"
          >
            Submit application
          </button>
          <a href="/dashboard" className="text-sm text-stone-500 hover:text-stone-800">
            Cancel
          </a>
        </div>
      </form>
    </div>
  )
}
