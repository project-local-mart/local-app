import { serve } from '@hono/node-server'
import { Hono } from 'hono'

const app = new Hono()

app.get('/health', (c) => {
  return c.json({ status: 'ok', version: '0.1.0' })
})

const port = parseInt(process.env['API_PORT'] ?? '3001', 10)

serve({ fetch: app.fetch, port }, () => {
  console.log(`API server running on port ${port}`)
})
