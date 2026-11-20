/**
 * Builds an absolute Localmart API URL. Server-side only: every API call in
 * this app runs in server components or server actions.
 *
 * `API_URL` is read on each call, not baked in at build time. On Vercel it is
 * set to the API project's URL; locally it falls back to the API dev server.
 */
export function apiUrl(path: string): string {
  const base = process.env['API_URL'] ?? 'http://localhost:3001'
  return `${base.replace(/\/+$/, '')}${path}`
}
