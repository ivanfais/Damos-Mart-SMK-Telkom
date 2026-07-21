"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resetPasswordSchema = exports.validateResetTokenSchema = exports.forgotPasswordSchema = exports.refreshTokenSchema = exports.ssoLoginSchema = exports.loginSchema = exports.registerSchema = void 0;
const zod_1 = require("zod");
exports.registerSchema = zod_1.z.object({
    body: zod_1.z.object({
        fullName: zod_1.z.string().min(3, 'Full name must be at least 3 characters long'),
        email: zod_1.z.string().email('Invalid email address'),
        phone: zod_1.z.string().optional().nullable(),
        password: zod_1.z.string().min(6, 'Password must be at least 6 characters long'),
        discType: zod_1.z.enum(['DOMINANCE', 'INFLUENCE', 'STEADINESS', 'CONSCIENTIOUSNESS']).optional().nullable(),
    }),
});
exports.loginSchema = zod_1.z.object({
    body: zod_1.z.object({
        email: zod_1.z.string().email('Invalid email address'),
        password: zod_1.z.string().min(1, 'Password is required'),
    }),
});
exports.ssoLoginSchema = zod_1.z.object({
    body: zod_1.z.object({
        ssoToken: zod_1.z.string().min(1, 'ssoToken is required'),
    }),
});
exports.refreshTokenSchema = zod_1.z.object({
    body: zod_1.z.object({
        refreshToken: zod_1.z.string().min(1, 'refreshToken is required'),
    }),
});
exports.forgotPasswordSchema = zod_1.z.object({
    body: zod_1.z.object({
        email: zod_1.z.string().email('Invalid email address'),
        client: zod_1.z.string().trim().min(1).optional(),
    }),
});
exports.validateResetTokenSchema = zod_1.z.object({
    query: zod_1.z.object({
        token: zod_1.z.string().min(1, 'Token is required'),
    }),
});
exports.resetPasswordSchema = zod_1.z.object({
    body: zod_1.z.union([
        zod_1.z.object({
            token: zod_1.z.string().min(1, 'Token is required'),
            newPassword: zod_1.z.string().min(6, 'Password must be at least 6 characters long'),
            confirmPassword: zod_1.z.string().min(6, 'Confirm password is required'),
        }),
        zod_1.z.object({
            email: zod_1.z.string().email('Invalid email address'),
            code: zod_1.z.string().length(4, 'Verification code must be 4 digits'),
            newPassword: zod_1.z.string().min(6, 'Password must be at least 6 characters long'),
        }),
    ]),
});
