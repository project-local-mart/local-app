import type { Context } from 'hono'
import { createMiddleware } from 'hono/factory'
import { verifyToken } from '@clerk/backend'
import { eq } from 'drizzle-orm'
import { db } from '../lib/db'
import { users } from '@localmart/db'
import type { UserRole } from '@localmart/types'

export interface AuthUser {
  id: string
  clerkId: string
  role: UserRole
  communityId: string | null
}

const USER_KEY = '__auth_user__'

/**
 * Verifies the Clerk JWT from the Authorization header and attaches
 * the local DB user to context. Returns 401 if the token is missing,
 * invalid, or the user has not yet been synced via webhook.
 */
export const verifyAuth = createMiddleware(async (c, next) => {
  const authHeader = c.req.header('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const token = authHeader.slice(7)
  const secretKey = process.env['CLERK_SECRET_KEY']
  if (!secretKey) {
    return c.json({ error: 'Server misconfiguration' }, 500)
  }

  let clerkUserId: string
  try {
    const payload = await verifyToken(token, { secretKey })
    clerkUserId = payload.sub
  } catch {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const [user] = await db.select().from(users).where(eq(users.clerkId, clerkUserId))
  if (!user) {
    return c.json({ error: 'User not found — please try again shortly' }, 401)
  }

  c.set(USER_KEY, {
    id: user.id,
    clerkId: user.clerkId,
    role: user.role,
    communityId: user.communityId,
  } satisfies AuthUser)

  return next()
})

/** Retrieve the authenticated user attached by verifyAuth. */
export function getUser(c: Context): AuthUser {
  return c.get(USER_KEY) as AuthUser
}
