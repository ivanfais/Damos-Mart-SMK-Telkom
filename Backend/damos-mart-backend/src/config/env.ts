import dotenv from 'dotenv';
import { z } from 'zod';

// Load .env variables
dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  REDIS_URL: z.string().optional().default('redis://localhost:6379'),
  JWT_ACCESS_SECRET: z.string().min(1, 'JWT_ACCESS_SECRET is required'),
  JWT_REFRESH_SECRET: z.string().min(1, 'JWT_REFRESH_SECRET is required'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),
  UPLOAD_DIR: z.string().default('./uploads'),
  MAX_FILE_SIZE: z.coerce.number().default(5242880),
  CORS_ORIGINS: z.string().transform((val) => val.split(',').map(item => item.trim())),
  API_PREFIX: z.string().default('/api/v1'),
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().default(587),
  SMTP_SECURE: z
    .string()
    .optional()
    .transform((val) => val === 'true'),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  SMTP_FROM: z.string().default('Damos Mart <noreply@damosmart.com>'),
  /**
   * Preferred on Railway: Resend HTTP API (SMTP to Gmail is often blocked).
   * https://resend.com — set RESEND_API_KEY and use a verified from-address in SMTP_FROM.
   */
  RESEND_API_KEY: z.string().optional(),
  /** Fallback reset URL prefix used by all DISC apps. */
  RESET_PASSWORD_URL: z
    .string()
    .default('http://localhost:8080/reset-password?token='),
  /** Optional per-variant reset URL overrides. */
  RESET_PASSWORD_URL_DOMINANCE: z.string().optional(),
  RESET_PASSWORD_URL_INFLUENCE: z.string().optional(),
  RESET_PASSWORD_URL_STEADINESS: z.string().optional(),
  RESET_PASSWORD_URL_CONSCIENTIOUSNESS: z.string().optional(),
  /**
   * Optional fallback 4-digit code when SMTP is not configured (local/demo only).
   * Empty string disables the demo fallback.
   */
  PASSWORD_RESET_DEMO_CODE: z
    .string()
    .optional()
    .transform((val) => (val && val.length === 4 ? val : '1234')),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', JSON.stringify(parsed.error.format(), null, 2));
  process.exit(1);
}

export const env = parsed.data;
export type Env = z.infer<typeof envSchema>;
