import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { logger as honoLogger } from 'hono/logger'
import { logger } from './lib/logger'
import { ValidationError } from './lib/validate'
import communities from './routes/communities'
import merchants from './routes/merchants'
import products from './routes/products'
import users from './routes/users'

const app = new Hono()

app.use('*', honoLogger())

app.get('/health', (c) => {
  return c.json({ status: 'ok', version: '0.1.0' })
})

app.route('/communities', communities)
app.route('/merchants', merchants)
app.route('/products', products)
app.route('/users', users)

app.notFound((c) => c.json({ error: 'Not found' }, 404))
app.onError((err, c) => {
  if (err instanceof ValidationError) {
    return c.json({ error: 'Validation failed', issues: err.issues }, 400)
  }
  logger.error({ err }, 'Unhandled error')
  return c.json({ error: 'Internal server error' }, 500)
})

const port = parseInt(process.env['API_PORT'] ?? '3001', 10)

serve({ fetch: app.fetch, port }, () => {
  logger.info(`API server running on port ${port}`)
})
