"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const zod_1 = require("zod");
// Load .env variables
dotenv_1.default.config();
const envSchema = zod_1.z.object({
    NODE_ENV: zod_1.z.enum(['development', 'production', 'test']).default('development'),
    PORT: zod_1.z.coerce.number().default(3000),
    DATABASE_URL: zod_1.z.string().min(1, 'DATABASE_URL is required'),
    REDIS_URL: zod_1.z.string().optional().default('redis://localhost:6379'),
    JWT_ACCESS_SECRET: zod_1.z.string().min(1, 'JWT_ACCESS_SECRET is required'),
    JWT_REFRESH_SECRET: zod_1.z.string().min(1, 'JWT_REFRESH_SECRET is required'),
    JWT_ACCESS_EXPIRES_IN: zod_1.z.string().default('15m'),
    JWT_REFRESH_EXPIRES_IN: zod_1.z.string().default('7d'),
    UPLOAD_DIR: zod_1.z.string().default('./uploads'),
    MAX_FILE_SIZE: zod_1.z.coerce.number().default(5242880),
    CORS_ORIGINS: zod_1.z.string().transform((val) => val.split(',').map(item => item.trim())),
    API_PREFIX: zod_1.z.string().default('/api/v1'),
    SMTP_HOST: zod_1.z.string().optional(),
    SMTP_PORT: zod_1.z.coerce.number().default(587),
    SMTP_SECURE: zod_1.z
        .string()
        .optional()
        .transform((val) => val === 'true'),
    SMTP_USER: zod_1.z.string().optional(),
    SMTP_PASS: zod_1.z.string().optional(),
    SMTP_FROM: zod_1.z.string().default('Damos Mart <noreply@damosmart.com>'),
    RESET_PASSWORD_URL: zod_1.z
        .string()
        .default('http://localhost:8080/reset-password?token='),
    /** App clients that use email reset links, e.g. `dominance`. Others use demo code. */
    PASSWORD_RESET_LINK_CLIENTS: zod_1.z
        .string()
        .optional()
        .default('dominance')
        .transform((val) => val
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .filter(Boolean)),
    /** Demo verification code for non-link clients. Set empty to disable demo flow. */
    PASSWORD_RESET_DEMO_CODE: zod_1.z.string().default('1234'),
});
const parsed = envSchema.safeParse(process.env);
if (!parsed.success) {
    console.error('❌ Invalid environment variables:', JSON.stringify(parsed.error.format(), null, 2));
    process.exit(1);
}
exports.env = parsed.data;
