import { createHmac, timingSafeEqual } from 'crypto'

const TOLERANCE_MS = 5 * 60 * 1000 // 5 minutes

/**
 * Verifies a Clerk webhook signature using HMAC-SHA256.
 *
 * Clerk signs webhooks as: HMAC-SHA256(secret, "{svix-id}.{svix-timestamp}.{rawBody}")
 * The secret is base64-encoded after stripping the "whsec_" prefix.
 *
 * Throws if the signature is invalid or the timestamp is too old.
 */
export function verifyWebhookSignature(
  rawBody: string,
  svixId: string,
  svixTimestamp: string,
  svixSignature: string,
  secret: string
): void {
  // Replay protection — reject requests older than 5 minutes
  const ts = parseInt(svixTimestamp, 10)
  if (isNaN(ts) || Date.now() - ts * 1000 > TOLERANCE_MS) {
    throw new Error('Webhook timestamp too old')
  }

  const keyBytes = Buffer.from(secret.replace(/^whsec_/, ''), 'base64')
  const signedContent = `${svixId}.${svixTimestamp}.${rawBody}`
  const expected = createHmac('sha256', keyBytes).update(signedContent).digest('base64')
  const expectedBuf = Buffer.from(expected)

  // svix-signature may contain multiple sigs: "v1,abc v1,def"
  const matched = svixSignature
    .split(' ')
    .filter((s) => s.startsWith('v1,'))
    .some((s) => {
      try {
        return timingSafeEqual(Buffer.from(s.slice(3), 'base64'), expectedBuf)
      } catch {
        return false
      }
    })

  if (!matched) throw new Error('Invalid webhook signature')
}
