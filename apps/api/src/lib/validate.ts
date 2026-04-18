import type { Context } from 'hono'
import type { ZodSchema, ZodError } from 'zod'

export class ValidationError extends Error {
  constructor(public readonly issues: ZodError['issues']) {
    super('Validation failed')
  }
}

/** Parse and validate the JSON body. Throws ValidationError on failure. */
export async function parseBody<T>(c: Context, schema: ZodSchema<T>): Promise<T> {
  const body: unknown = await c.req.json()
  const result = schema.safeParse(body)
  if (!result.success) throw new ValidationError(result.error.issues)
  return result.data
}
