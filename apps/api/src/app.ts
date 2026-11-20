import { Hono } from 'hono'
import { logger as honoLogger } from 'hono/logger'
import { logger } from './lib/logger'
import { ValidationError } from './lib/validate'
import communities from './routes/communities'
import merchants from './routes/merchants'
import products from './routes/products'
import users from './routes/users'

const routes = new Hono()

routes.get('/health', (c) => {
  return c.json({ status: 'ok', version: '0.1.0' })
})

routes.route('/communities', communities)
routes.route('/merchants', merchants)
routes.route('/products', products)
routes.route('/users', users)

const app = new Hono()

app.use('*', honoLogger())

// Routes are served at the root (local development, the standalone Vercel API
// project) and under `/api`, so the API also works behind a same-domain `/api`
// rewrite, such as Vercel Services, which forwards the prefix unchanged.
app.route('/api', routes)
app.route('/', routes)

app.notFound((c) => c.json({ error: 'Not found' }, 404))
app.onError((err, c) => {
  if (err instanceof ValidationError) {
    return c.json({ error: 'Validation failed', issues: err.issues }, 400)
  }
  logger.error({ err }, 'Unhandled error')
  return c.json({ error: 'Internal server error' }, 500)
})

// Vercel detects and deploys this default Hono export as a Function. The
// regular Node entry point in index.ts imports the same app for local and
// container-based development.
export default app
