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
    client: z.string().trim().min(1).optional(),
  }),
});

export const validateResetTokenSchema = z.object({
  query: z.object({
    token: z.string().min(1, 'Token is required'),
  }),
});

export const resetPasswordSchema = z.object({
  body: z.union([
    z.object({
      token: z.string().min(1, 'Token is required'),
      newPassword: z.string().min(6, 'Password must be at least 6 characters long'),
      confirmPassword: z.string().min(6, 'Confirm password is required'),
    }),
    z.object({
      email: z.string().email('Invalid email address'),
      code: z.string().length(4, 'Verification code must be 4 digits'),
      newPassword: z.string().min(6, 'Password must be at least 6 characters long'),
    }),
  ]),
});

export type ResetPasswordTokenInput = {
  token: string;
  newPassword: string;
  confirmPassword: string;
};

export type ResetPasswordDemoInput = {
  email: string;
  code: string;
  newPassword: string;
};

export type ResetPasswordInput = ResetPasswordTokenInput | ResetPasswordDemoInput;

export type RegisterInput = z.infer<typeof registerSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];
export type SsoLoginInput = z.infer<typeof ssoLoginSchema>['body'];
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>['body'];
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>['body'];
