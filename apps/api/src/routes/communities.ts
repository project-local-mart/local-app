import { Hono } from 'hono'
import { z } from 'zod'
import { eq } from 'drizzle-orm'
import { db } from '../lib/db'
import { communities } from '@localmart/db'
import { verifyAuth } from '../middleware/auth'
import { requireRole } from '../middleware/rbac'
import { parseBody } from '../lib/validate'

const router = new Hono()

const CreateCommunitySchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  slug: z.string().min(1).regex(/^[a-z0-9-]+$/),
  zipCodes: z.array(z.string().length(5)).min(1),
})

const UpdateCommunitySchema = z.object({
  name: z.string().min(1).optional(),
  zipCodes: z.array(z.string().length(5)).min(1).optional(),
})

// GET /communities
router.get('/', async (c) => {
  const rows = await db.select().from(communities)
  return c.json(rows)
})

// GET /communities/:slug
router.get('/:slug', async (c) => {
  const slug = c.req.param('slug')
  const [community] = await db
    .select()
    .from(communities)
    .where(eq(communities.slug, slug))
  if (!community) return c.json({ error: 'Not found' }, 404)
  return c.json(community)
})

// POST /communities — platform_admin only
router.post('/', verifyAuth, requireRole('platform_admin'), async (c) => {
  const body = await parseBody(c, CreateCommunitySchema)
  const [community] = await db
    .insert(communities)
    .values(body)
    .onConflictDoNothing()
    .returning()
  if (!community) return c.json({ error: 'Community already exists' }, 409)
  return c.json(community, 201)
})

// PATCH /communities/:id — platform_admin only
router.patch('/:id', verifyAuth, requireRole('platform_admin'), async (c) => {
  const id = c.req.param('id')
  const body = await parseBody(c, UpdateCommunitySchema)
  const [community] = await db
    .update(communities)
    .set({ ...body, updatedAt: new Date() })
    .where(eq(communities.id, id))
    .returning()
  if (!community) return c.json({ error: 'Not found' }, 404)
  return c.json(community)
})

export default router
