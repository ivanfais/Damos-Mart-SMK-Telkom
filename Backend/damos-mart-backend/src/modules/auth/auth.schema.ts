import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    fullName: z.string().min(3, 'Full name must be at least 3 characters long'),
    email: z.string().email('Invalid email address'),
    phone: z.string().optional().nullable(),
    password: z.string().min(6, 'Password must be at least 6 characters long'),
    discType: z.enum(['DOMINANCE', 'INFLUENCE', 'STEADINESS', 'CONSCIENTIOUSNESS']).optional().nullable(),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(1, 'Password is required'),
  }),
});

export const ssoLoginSchema = z.object({
  body: z.object({
    ssoToken: z.string().min(1, 'ssoToken is required'),
  }),
});

export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'refreshToken is required'),
  }),
});

export const forgotPasswordSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
  }),
});

export const resetPasswordSchema = z.object({
  body: z.object({
<<<<<<< HEAD
    token: z.string().min(1, 'Reset token is required'),
    newPassword: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
      .regex(/[0-9]/, 'Password must contain at least one number')
      .regex(/[@$!]/, 'Password must contain at least one symbol (@, $, or !)'),
    confirmPassword: z.string().min(1, 'Password confirmation is required'),
  }).refine((data) => data.newPassword === data.confirmPassword, {
    message: 'Password confirmation does not match',
    path: ['confirmPassword'],
  }),
});

export const validateResetTokenSchema = z.object({
  query: z.object({
    token: z.string().min(1, 'Reset token is required'),
=======
    email: z.string().email('Invalid email address'),
    code: z.string().length(4, 'Verification code must be 4 digits'),
    newPassword: z.string().min(6, 'Password must be at least 6 characters long'),
>>>>>>> 58529ed1321260144e21ae22a4aaacbfa419a7ed
  }),
});

export type RegisterInput = z.infer<typeof registerSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];
export type SsoLoginInput = z.infer<typeof ssoLoginSchema>['body'];
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>['body'];
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>['body'];
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>['body'];
