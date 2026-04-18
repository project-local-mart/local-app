import { Hono } from 'hono'
import { z } from 'zod'
import { eq, and } from 'drizzle-orm'
import { db } from '../lib/db'
import { merchants } from '@localmart/db'
import { verifyAuth, getUser } from '../middleware/auth'
import { requireRole } from '../middleware/rbac'
import { parseBody } from '../lib/validate'

const router = new Hono()

const CreateMerchantSchema = z.object({
  communityId: z.string().min(1),
  businessName: z.string().min(1),
  ownerName: z.string().min(1),
  email: z.string().email(),
  phone: z.string().min(7),
  address: z.string().min(1),
  city: z.string().min(1),
  state: z.string().length(2),
  zip: z.string().length(5),
  lat: z.number(),
  lng: z.number(),
})

// GET /merchants?communityId=...
router.get('/', async (c) => {
  const communityId = c.req.query('communityId')
  const rows = communityId
    ? await db.select().from(merchants).where(eq(merchants.communityId, communityId))
    : await db.select().from(merchants)
  return c.json(rows)
})

// GET /merchants/:id
router.get('/:id', async (c) => {
  const [merchant] = await db
    .select()
    .from(merchants)
    .where(eq(merchants.id, c.req.param('id')))
  if (!merchant) return c.json({ error: 'Not found' }, 404)
  return c.json(merchant)
})

// GET /merchants/me — merchant record for the authenticated user
router.get('/me', verifyAuth, async (c) => {
  const { id: userId } = getUser(c)
  const [merchant] = await db
    .select()
    .from(merchants)
    .where(eq(merchants.userId, userId))
  if (!merchant) return c.json({ error: 'No merchant record found' }, 404)
  return c.json(merchant)
})

// POST /merchants — submit application (any authenticated user)
router.post('/', verifyAuth, async (c) => {
  const body = await parseBody(c, CreateMerchantSchema)
  const { id: userId } = getUser(c)
  const id = `merchant_${Date.now()}`
  const [merchant] = await db
    .insert(merchants)
    .values({ id, userId, ...body })
    .returning()
  return c.json(merchant, 201)
})

// POST /merchants/:id/approve
router.post('/:id/approve', verifyAuth, requireRole('platform_admin', 'moderator'), async (c) => {
  const user = getUser(c)
  const [merchant] = await db
    .update(merchants)
    .set({ status: 'approved', approvedBy: user.id, approvedAt: new Date(), updatedAt: new Date() })
    .where(and(eq(merchants.id, c.req.param('id')), eq(merchants.status, 'pending')))
    .returning()
  if (!merchant) return c.json({ error: 'Not found or not pending' }, 404)
  return c.json(merchant)
})

// POST /merchants/:id/reject
router.post('/:id/reject', verifyAuth, requireRole('platform_admin', 'moderator'), async (c) => {
  const [merchant] = await db
    .update(merchants)
    .set({ status: 'rejected', updatedAt: new Date() })
    .where(and(eq(merchants.id, c.req.param('id')), eq(merchants.status, 'pending')))
    .returning()
  if (!merchant) return c.json({ error: 'Not found or not pending' }, 404)
  return c.json(merchant)
})

// POST /merchants/:id/suspend
router.post('/:id/suspend', verifyAuth, requireRole('platform_admin'), async (c) => {
  const [merchant] = await db
    .update(merchants)
    .set({ status: 'suspended', updatedAt: new Date() })
    .where(and(eq(merchants.id, c.req.param('id')), eq(merchants.status, 'approved')))
    .returning()
  if (!merchant) return c.json({ error: 'Not found or not approved' }, 404)
  return c.json(merchant)
})

export default router
