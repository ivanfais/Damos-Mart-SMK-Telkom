import prisma from '../../config/database';
import { env } from '../../config/env';
import { hashPassword, comparePassword } from '../../utils/hash';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  TokenPayload,
} from '../../utils/jwt';
import { AppError } from '../../middlewares/error.middleware';
import { sendPasswordResetEmail } from '../../services/email.service';
import { generateResetToken, hashResetToken } from '../../utils/reset-token';
import { RegisterInput, LoginInput, SsoLoginInput, ForgotPasswordInput, ResetPasswordInput, ResetPasswordTokenInput, ResetPasswordDemoInput } from './auth.schema';

const PASSWORD_RESET_EXPIRY_MS = 60 * 60 * 1000;

function resolvePasswordResetMethod(client?: string): 'email' | 'demo' {
  const normalizedClient = client?.trim().toLowerCase();

  if (
    normalizedClient &&
    env.PASSWORD_RESET_LINK_CLIENTS.includes(normalizedClient)
  ) {
    return 'email';
  }

  if (env.PASSWORD_RESET_DEMO_CODE) {
    return 'demo';
  }

  return 'email';
}

function isTokenResetInput(input: ResetPasswordInput): input is ResetPasswordTokenInput {
  return 'token' in input;
}

/**
 * Computes the refresh token's DB expiry from JWT_REFRESH_EXPIRES_IN (e.g. "30d", "12h"),
 * so the stored expiry always matches the signed JWT's own lifetime.
 */
function refreshTokenExpiresAt(): Date {
  const match = /^(\d+)\s*(d|h|m|s)$/i.exec(env.JWT_REFRESH_EXPIRES_IN.trim());
  const amount = match ? parseInt(match[1], 10) : 7;
  const unit = match ? match[2].toLowerCase() : 'd';
  const msPerUnit: Record<string, number> = { d: 86400000, h: 3600000, m: 60000, s: 1000 };

  return new Date(Date.now() + amount * (msPerUnit[unit] ?? msPerUnit.d));
}

/**
 * Strips password hash from user object.
 */
function sanitizeUser(user: any) {
  const { passwordHash, ...sanitized } = user;
  return sanitized;
}

export class AuthService {
  /**
   * Registers a new student.
   */
  async register(input: RegisterInput) {
    const existingUser = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (existingUser) {
      throw new AppError(409, 'EMAIL_EXISTS', 'Email is already registered');
    }

    const hashed = await hashPassword(input.password);

    const user = await prisma.user.create({
      data: {
        fullName: input.fullName,
        email: input.email,
        phone: input.phone,
        passwordHash: hashed,
        role: 'STUDENT',
        discType: input.discType || null,
        isActive: true,
      },
    });

    const payload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    // Save refresh token in database (expires in 7 days)
    const expiresAt = refreshTokenExpiresAt();

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt,
      },
    });

    return {
      user: sanitizeUser(user),
      accessToken,
      refreshToken,
    };
  }

  /**
   * Logs in a user via email and password.
   */
  async login(input: LoginInput) {
    const user = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (!user) {
      throw new AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
    }

    if (!user.isActive) {
      throw new AppError(403, 'FORBIDDEN', 'User account is inactive. Please contact administrator.');
    }

    const isMatch = await comparePassword(input.password, user.passwordHash);
    if (!isMatch) {
      throw new AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
    }

    const payload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    const expiresAt = refreshTokenExpiresAt();

    // Remove old refresh tokens for this user to keep db clean
    await prisma.refreshToken.deleteMany({
      where: { userId: user.id }
    });

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt,
      },
    });

    return {
      user: sanitizeUser(user),
      accessToken,
      refreshToken,
    };
  }

  /**
   * Logs in a student using School SSO token simulation.
   */
  async loginSso(input: SsoLoginInput) {
    // Simulation: Decode the SSO token (e.g. ssoToken contains "ssoId:fullName:email")
    // If it's a general token, mock-decode it to user details.
    let ssoId = 'sso-default';
    let fullName = 'SSO Student';
    let email = 'sso.student@smktelkom-jkt.sch.id';

    if (input.ssoToken.includes(':')) {
      const parts = input.ssoToken.split(':');
      ssoId = parts[0] || ssoId;
      fullName = parts[1] || fullName;
      email = parts[2] || email;
    } else {
      // Create a unique SSO key using the input token
      ssoId = `sso-${input.ssoToken}`;
      fullName = `SSO Student ${input.ssoToken.substring(0, 5)}`;
      email = `sso.${input.ssoToken.substring(0, 8)}@smktelkom-jkt.sch.id`;
    }

    // Upsert user based on email (or ssoId)
    let user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      const randomPassword = Math.random().toString(36).substring(2, 15);
      const hashed = await hashPassword(randomPassword);

      user = await prisma.user.create({
        data: {
          fullName,
          email,
          ssoId,
          passwordHash: hashed,
          role: 'STUDENT',
          isActive: true,
        },
      });
    } else {
      // Check if user is active
      if (!user.isActive) {
        throw new AppError(403, 'FORBIDDEN', 'User account is inactive. Please contact administrator.');
      }
      
      // Update ssoId if not present
      if (!user.ssoId) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { ssoId },
        });
      }
    }

    const payload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    const expiresAt = refreshTokenExpiresAt();

    await prisma.refreshToken.deleteMany({
      where: { userId: user.id }
    });

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt,
      },
    });

    return {
      user: sanitizeUser(user),
      accessToken,
      refreshToken,
    };
  }

  /**
   * Refreshes JWT access token using refresh token.
   */
  async refresh(token: string) {
    // 1. Verify token signature
    let decoded: TokenPayload;
    try {
      decoded = verifyRefreshToken(token);
    } catch {
      throw new AppError(401, 'INVALID_TOKEN', 'Refresh token is expired or invalid');
    }

    // 2. Check token in database
    const savedToken = await prisma.refreshToken.findUnique({
      where: { token },
    });

    if (!savedToken) {
      throw new AppError(401, 'INVALID_TOKEN', 'Refresh token not found or revoked');
    }

    if (savedToken.expiresAt < new Date()) {
      await prisma.refreshToken.delete({ where: { token } });
      throw new AppError(401, 'EXPIRED_TOKEN', 'Refresh token has expired');
    }

    // 3. Find user
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
    });

    if (!user || !user.isActive) {
      throw new AppError(401, 'UNAUTHORIZED', 'User not found or inactive');
    }

    // 4. Generate new tokens
    const payload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = generateAccessToken(payload);
    const newRefreshToken = generateRefreshToken(payload);

    // Update in database (rotate refresh token)
    const expiresAt = refreshTokenExpiresAt();

    await prisma.refreshToken.delete({
      where: { token },
    });

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: newRefreshToken,
        expiresAt,
      },
    });

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  }

  /**
   * Revokes refresh token (Logout).
   */
  async logout(token: string) {
    try {
      await prisma.refreshToken.delete({
        where: { token },
      });
    } catch {
      // Fail silently if token is already deleted or not found
    }
  }

  /**
   * Sends a password reset link to the user's email.
   */
  async requestPasswordReset(input: ForgotPasswordInput) {
    const user = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'Email tidak terdaftar');
    }

    if (!user.isActive) {
      throw new AppError(403, 'FORBIDDEN', 'Akun tidak aktif. Hubungi administrator.');
    }

    const method = resolvePasswordResetMethod(input.client);

    if (method === 'demo') {
      if (!env.PASSWORD_RESET_DEMO_CODE) {
        throw new AppError(
          400,
          'DEMO_RESET_DISABLED',
          'Reset password demo tidak tersedia. Hubungi administrator.',
        );
      }

      return {
        email: user.email,
        method: 'demo' as const,
        message: 'Kode verifikasi telah dikirim. Gunakan kode demo untuk melanjutkan reset password.',
      };
    }

    const rawToken = generateResetToken();
    const tokenHash = hashResetToken(rawToken);
    const expiresAt = new Date(Date.now() + PASSWORD_RESET_EXPIRY_MS);

    await prisma.passwordResetToken.deleteMany({
      where: {
        userId: user.id,
        usedAt: null,
      },
    });

    await prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt,
      },
    });

    const resetUrl = `${env.RESET_PASSWORD_URL}${rawToken}`;
    await sendPasswordResetEmail({
      to: user.email,
      fullName: user.fullName,
      resetUrl,
    });

    return {
      email: user.email,
      method: 'email' as const,
      message: 'Link reset password telah dikirim ke email Anda. Periksa kotak masuk Gmail Anda.',
    };
  }

  /**
   * Validates whether a password reset token is still usable.
   */
  async validateResetToken(token: string) {
    const tokenHash = hashResetToken(token);
    const savedToken = await prisma.passwordResetToken.findUnique({
      where: { tokenHash },
    });

    const valid =
      !!savedToken &&
      savedToken.usedAt == null &&
      savedToken.expiresAt > new Date();

    return { valid };
  }

  /**
   * Resets password using a one-time token from the reset email link.
   */
  async resetPassword(input: ResetPasswordInput) {
    if (isTokenResetInput(input)) {
      return this.resetPasswordWithToken(input);
    }

    return this.resetPasswordWithDemoCode(input);
  }

  private async resetPasswordWithToken(input: ResetPasswordTokenInput) {
    if (input.newPassword !== input.confirmPassword) {
      throw new AppError(400, 'PASSWORD_MISMATCH', 'Konfirmasi password tidak sesuai');
    }

    const tokenHash = hashResetToken(input.token);
    const savedToken = await prisma.passwordResetToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (!savedToken || savedToken.usedAt != null || savedToken.expiresAt < new Date()) {
      throw new AppError(400, 'INVALID_TOKEN', 'Link reset password tidak valid atau sudah kedaluwarsa');
    }

    const user = savedToken.user;
    if (!user.isActive) {
      throw new AppError(403, 'FORBIDDEN', 'Akun tidak aktif. Hubungi administrator.');
    }

    const hashed = await hashPassword(input.newPassword);

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { passwordHash: hashed },
      }),
      prisma.passwordResetToken.update({
        where: { id: savedToken.id },
        data: { usedAt: new Date() },
      }),
      prisma.refreshToken.deleteMany({
        where: { userId: user.id },
      }),
    ]);

    return {
      email: user.email,
      message: 'Password berhasil diperbarui',
    };
  }

  private async resetPasswordWithDemoCode(input: ResetPasswordDemoInput) {
    if (!env.PASSWORD_RESET_DEMO_CODE) {
      throw new AppError(400, 'DEMO_RESET_DISABLED', 'Reset password demo tidak tersedia');
    }

    if (input.code !== env.PASSWORD_RESET_DEMO_CODE) {
      throw new AppError(400, 'INVALID_CODE', 'Kode verifikasi salah');
    }

    const user = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'Email tidak terdaftar');
    }

    if (!user.isActive) {
      throw new AppError(403, 'FORBIDDEN', 'Akun tidak aktif. Hubungi administrator.');
    }

    const hashed = await hashPassword(input.newPassword);

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { passwordHash: hashed },
      }),
      prisma.refreshToken.deleteMany({
        where: { userId: user.id },
      }),
    ]);

    return {
      email: user.email,
      message: 'Password berhasil diperbarui',
    };
  }
}
export default AuthService;
