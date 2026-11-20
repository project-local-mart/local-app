import postgres from 'postgres'
import { drizzle } from 'drizzle-orm/postgres-js'
import * as schema from './schema'

const DATABASE_URL =
  process.env['DATABASE_URL'] ??
  'postgresql://localmart:localmart_dev_password@localhost:5432/localmart_dev'

// Serverless functions may create several short-lived runtimes at once. Keep
// each runtime's pool deliberately small and point DATABASE_URL at the
// provider's transaction-mode pooler (for Supabase, the Supavisor URL on port
// 6543). Transaction-mode poolers do not support prepared statements.
const isServerless = Boolean(process.env['VERCEL'])
const client = postgres(DATABASE_URL, {
  max: isServerless ? 1 : 10,
  prepare: !isServerless,
  idle_timeout: 20,
  connect_timeout: 10,
})
export const db = drizzle(client, { schema })
export type DB = typeof db
