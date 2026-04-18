import { createMiddleware } from 'hono/factory'
import type { UserRole } from '@localmart/types'
import { getUser } from './auth'

export function requireRole(...roles: UserRole[]) {
  return createMiddleware(async (c, next) => {
    const user = getUser(c)
    if (!roles.includes(user.role)) {
      return c.json({ error: 'Forbidden' }, 403)
    }
    return next()
  })
}
