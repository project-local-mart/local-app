import { serve } from '@hono/node-server'
import app from './app'
import { logger } from './lib/logger'

const port = parseInt(process.env['API_PORT'] ?? '3001', 10)

serve({ fetch: app.fetch, port }, () => {
  logger.info(`API server running on port ${port}`)
})
