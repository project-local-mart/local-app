import postgres from 'postgres'
import { drizzle } from 'drizzle-orm/postgres-js'
import * as schema from './schema'

const DATABASE_URL =
  process.env['DATABASE_URL'] ??
  'postgresql://localmart:localmart_dev_password@localhost:5432/localmart_dev'

const client = postgres(DATABASE_URL)
export const db = drizzle(client, { schema })
export type DB = typeof db
