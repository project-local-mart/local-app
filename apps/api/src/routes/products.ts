import { Hono } from 'hono'
import { z } from 'zod'
import { eq, and } from 'drizzle-orm'
import { db } from '../lib/db'
import { products } from '@localmart/db'
import { verifyAuth, getUser } from '../middleware/auth'
import { requireRole } from '../middleware/rbac'
import { parseBody } from '../lib/validate'

const router = new Hono()

const CreateProductSchema = z.object({
  merchantId: z.string().min(1),
  name: z.string().min(1),
  description: z.string().optional(),
  price: z.number().int().positive(),
  stockQuantity: z.number().int().min(0),
  sku: z.string().optional(),
  barcode: z.string().optional(),
  images: z.array(z.string().url()).default([]),
  categories: z.array(z.string()).default([]),
})

const UpdateProductSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  price: z.number().int().positive().optional(),
  stockQuantity: z.number().int().min(0).optional(),
  images: z.array(z.string().url()).optional(),
  categories: z.array(z.string()).optional(),
})

const ModerateProductSchema = z.object({
  status: z.enum(['clean', 'flagged', 'held']),
})

// GET /products?merchantId=...
router.get('/', async (c) => {
  const merchantId = c.req.query('merchantId')
  const rows = merchantId
    ? await db
        .select()
        .from(products)
        .where(and(eq(products.merchantId, merchantId), eq(products.isPublished, true)))
    : await db.select().from(products).where(eq(products.isPublished, true))
  return c.json(rows)
})

// GET /products/:id
router.get('/:id', async (c) => {
  const [product] = await db
    .select()
    .from(products)
    .where(eq(products.id, c.req.param('id')))
  if (!product) return c.json({ error: 'Not found' }, 404)
  return c.json(product)
})

// POST /products — merchant only
router.post('/', verifyAuth, requireRole('merchant'), async (c) => {
  const body = await parseBody(c, CreateProductSchema)
  const id = `product_${Date.now()}`
  const [product] = await db
    .insert(products)
    .values({ id, ...body })
    .returning()
  return c.json(product, 201)
})

// PATCH /products/:id — merchant only
router.patch('/:id', verifyAuth, requireRole('merchant'), async (c) => {
  const body = await parseBody(c, UpdateProductSchema)
  const [product] = await db
    .update(products)
    .set({ ...body, updatedAt: new Date() })
    .where(eq(products.id, c.req.param('id')))
    .returning()
  if (!product) return c.json({ error: 'Not found' }, 404)
  return c.json(product)
})

// DELETE /products/:id — merchant or platform_admin
router.delete('/:id', verifyAuth, requireRole('merchant', 'platform_admin'), async (c) => {
  const [product] = await db
    .delete(products)
    .where(eq(products.id, c.req.param('id')))
    .returning()
  if (!product) return c.json({ error: 'Not found' }, 404)
  return c.json({ success: true })
})

// POST /products/:id/publish — merchant only; must be moderation clean
router.post('/:id/publish', verifyAuth, requireRole('merchant'), async (c) => {
  const [product] = await db
    .update(products)
    .set({ isPublished: true, updatedAt: new Date() })
    .where(
      and(
        eq(products.id, c.req.param('id')),
        eq(products.moderationStatus, 'clean')
      )
    )
    .returning()
  if (!product) return c.json({ error: 'Not found or not approved for publishing' }, 404)
  return c.json(product)
})

// POST /products/:id/moderate — platform_admin or moderator
router.post('/:id/moderate', verifyAuth, requireRole('platform_admin', 'moderator'), async (c) => {
  const { status } = await parseBody(c, ModerateProductSchema)
  const [product] = await db
    .update(products)
    .set({ moderationStatus: status, updatedAt: new Date() })
    .where(eq(products.id, c.req.param('id')))
    .returning()
  if (!product) return c.json({ error: 'Not found' }, 404)
  return c.json(product)
})

export default router
