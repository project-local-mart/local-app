import { Hono } from 'hono'
import { z } from 'zod'
import { eq } from 'drizzle-orm'
import { db } from '../lib/db'
import { users } from '@localmart/db'
import { verifyAuth, getUser } from '../middleware/auth'
import { requireRole } from '../middleware/rbac'
import { parseBody } from '../lib/validate'
import { verifyWebhookSignature } from '../lib/webhook'

const router = new Hono()

// Clerk webhook event shape (minimal — only fields we use)
const ClerkUserDataSchema = z.object({
  id: z.string(),
  email_addresses: z.array(z.object({ email_address: z.string() })).min(1),
})

const WebhookSchema = z.object({
  type: z.enum(['user.created', 'user.updated', 'user.deleted']),
  data: ClerkUserDataSchema,
})

const UpdateRoleSchema = z.object({
  role: z.enum(['platform_admin', 'moderator', 'merchant', 'consumer']),
  communityId: z.string().optional(),
})

// GET /users/me
router.get('/me', verifyAuth, async (c) => {
  const { id } = getUser(c)
  const [user] = await db.select().from(users).where(eq(users.id, id))
  if (!user) return c.json({ error: 'Not found' }, 404)
  return c.json(user)
})

// GET /users/:id — platform_admin only
router.get('/:id', verifyAuth, requireRole('platform_admin'), async (c) => {
  const [user] = await db
    .select()
    .from(users)
    .where(eq(users.id, c.req.param('id')))
  if (!user) return c.json({ error: 'Not found' }, 404)
  return c.json(user)
})

// POST /users/webhook — Clerk user lifecycle events
router.post('/webhook', async (c) => {
  const svixId = c.req.header('svix-id') ?? ''
  const svixTimestamp = c.req.header('svix-timestamp') ?? ''
  const svixSignature = c.req.header('svix-signature') ?? ''
  const webhookSecret = process.env['CLERK_WEBHOOK_SECRET'] ?? ''

  const rawBody = await c.req.text()

  try {
    verifyWebhookSignature(rawBody, svixId, svixTimestamp, svixSignature, webhookSecret)
  } catch {
    return c.json({ error: 'Invalid signature' }, 400)
  }

  const parsed = WebhookSchema.safeParse(JSON.parse(rawBody))
  if (!parsed.success) return c.json({ error: 'Invalid payload' }, 400)
  const { type, data } = parsed.data
  const clerkId = data.id
  const email = data.email_addresses[0]?.email_address ?? ''

  if (type === 'user.created') {
    await db
      .insert(users)
      .values({
        id: `user_${clerkId}`,
        clerkId,
        email,
        role: 'consumer',
      })
      .onConflictDoNothing()
  } else if (type === 'user.updated') {
    await db
      .update(users)
      .set({ email, updatedAt: new Date() })
      .where(eq(users.clerkId, clerkId))
  } else if (type === 'user.deleted') {
    await db.delete(users).where(eq(users.clerkId, clerkId))
  }

  return c.json({ received: true })
})

// PATCH /users/:id/role — platform_admin only
router.patch('/:id/role', verifyAuth, requireRole('platform_admin'), async (c) => {
  const { role, communityId } = await parseBody(c, UpdateRoleSchema)
  const [user] = await db
    .update(users)
    .set({ role, communityId: communityId ?? null, updatedAt: new Date() })
    .where(eq(users.id, c.req.param('id')))
    .returning()
  if (!user) return c.json({ error: 'Not found' }, 404)
  return c.json(user)
})

export default router
