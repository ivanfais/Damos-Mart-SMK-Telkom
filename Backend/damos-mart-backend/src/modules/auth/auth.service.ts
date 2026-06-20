import prisma from '../../config/database';
import { hashPassword, comparePassword } from '../../utils/hash';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  TokenPayload,
} from '../../utils/jwt';
import { AppError } from '../../middlewares/error.middleware';
import { RegisterInput, LoginInput, SsoLoginInput } from './auth.schema';

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
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

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

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

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

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

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
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

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
}
export default AuthService;
