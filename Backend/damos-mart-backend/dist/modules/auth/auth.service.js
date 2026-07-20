"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const env_1 = require("../../config/env");
const hash_1 = require("../../utils/hash");
const jwt_1 = require("../../utils/jwt");
const error_middleware_1 = require("../../middlewares/error.middleware");
const email_service_1 = require("../../services/email.service");
const reset_token_1 = require("../../utils/reset-token");
const PASSWORD_RESET_EXPIRY_MS = 60 * 60 * 1000;
function resolvePasswordResetMethod(client) {
    const normalizedClient = client?.trim().toLowerCase();
    if (normalizedClient &&
        env_1.env.PASSWORD_RESET_LINK_CLIENTS.includes(normalizedClient)) {
        return 'email';
    }
    if (env_1.env.PASSWORD_RESET_DEMO_CODE) {
        return 'demo';
    }
    return 'email';
}
function isTokenResetInput(input) {
    return 'token' in input;
}
/**
 * Computes the refresh token's DB expiry from JWT_REFRESH_EXPIRES_IN (e.g. "30d", "12h"),
 * so the stored expiry always matches the signed JWT's own lifetime.
 */
function refreshTokenExpiresAt() {
    const match = /^(\d+)\s*(d|h|m|s)$/i.exec(env_1.env.JWT_REFRESH_EXPIRES_IN.trim());
    const amount = match ? parseInt(match[1], 10) : 7;
    const unit = match ? match[2].toLowerCase() : 'd';
    const msPerUnit = { d: 86400000, h: 3600000, m: 60000, s: 1000 };
    return new Date(Date.now() + amount * (msPerUnit[unit] ?? msPerUnit.d));
}
/**
 * Strips password hash from user object.
 */
function sanitizeUser(user) {
    const { passwordHash, ...sanitized } = user;
    return sanitized;
}
class AuthService {
    /**
     * Registers a new student.
     */
    async register(input) {
        const existingUser = await database_1.default.user.findUnique({
            where: { email: input.email },
        });
        if (existingUser) {
            throw new error_middleware_1.AppError(409, 'EMAIL_EXISTS', 'Email is already registered');
        }
        const hashed = await (0, hash_1.hashPassword)(input.password);
        const user = await database_1.default.user.create({
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
        const payload = {
            userId: user.id,
            email: user.email,
            role: user.role,
        };
        const accessToken = (0, jwt_1.generateAccessToken)(payload);
        const refreshToken = (0, jwt_1.generateRefreshToken)(payload);
        // Save refresh token in database (expires in 7 days)
        const expiresAt = refreshTokenExpiresAt();
        await database_1.default.refreshToken.create({
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
    async login(input) {
        const user = await database_1.default.user.findUnique({
            where: { email: input.email },
        });
        if (!user) {
            throw new error_middleware_1.AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
        }
        if (!user.isActive) {
            throw new error_middleware_1.AppError(403, 'FORBIDDEN', 'User account is inactive. Please contact administrator.');
        }
        const isMatch = await (0, hash_1.comparePassword)(input.password, user.passwordHash);
        if (!isMatch) {
            throw new error_middleware_1.AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
        }
        const payload = {
            userId: user.id,
            email: user.email,
            role: user.role,
        };
        const accessToken = (0, jwt_1.generateAccessToken)(payload);
        const refreshToken = (0, jwt_1.generateRefreshToken)(payload);
        const expiresAt = refreshTokenExpiresAt();
        // Remove old refresh tokens for this user to keep db clean
        await database_1.default.refreshToken.deleteMany({
            where: { userId: user.id }
        });
        await database_1.default.refreshToken.create({
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
    async loginSso(input) {
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
        }
        else {
            // Create a unique SSO key using the input token
            ssoId = `sso-${input.ssoToken}`;
            fullName = `SSO Student ${input.ssoToken.substring(0, 5)}`;
            email = `sso.${input.ssoToken.substring(0, 8)}@smktelkom-jkt.sch.id`;
        }
        // Upsert user based on email (or ssoId)
        let user = await database_1.default.user.findUnique({
            where: { email },
        });
        if (!user) {
            const randomPassword = Math.random().toString(36).substring(2, 15);
            const hashed = await (0, hash_1.hashPassword)(randomPassword);
            user = await database_1.default.user.create({
                data: {
                    fullName,
                    email,
                    ssoId,
                    passwordHash: hashed,
                    role: 'STUDENT',
                    isActive: true,
                },
            });
        }
        else {
            // Check if user is active
            if (!user.isActive) {
                throw new error_middleware_1.AppError(403, 'FORBIDDEN', 'User account is inactive. Please contact administrator.');
            }
            // Update ssoId if not present
            if (!user.ssoId) {
                user = await database_1.default.user.update({
                    where: { id: user.id },
                    data: { ssoId },
                });
            }
        }
        const payload = {
            userId: user.id,
            email: user.email,
            role: user.role,
        };
        const accessToken = (0, jwt_1.generateAccessToken)(payload);
        const refreshToken = (0, jwt_1.generateRefreshToken)(payload);
        const expiresAt = refreshTokenExpiresAt();
        await database_1.default.refreshToken.deleteMany({
            where: { userId: user.id }
        });
        await database_1.default.refreshToken.create({
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
    async refresh(token) {
        // 1. Verify token signature
        let decoded;
        try {
            decoded = (0, jwt_1.verifyRefreshToken)(token);
        }
        catch {
            throw new error_middleware_1.AppError(401, 'INVALID_TOKEN', 'Refresh token is expired or invalid');
        }
        // 2. Check token in database
        const savedToken = await database_1.default.refreshToken.findUnique({
            where: { token },
        });
        if (!savedToken) {
            throw new error_middleware_1.AppError(401, 'INVALID_TOKEN', 'Refresh token not found or revoked');
        }
        if (savedToken.expiresAt < new Date()) {
            await database_1.default.refreshToken.delete({ where: { token } });
            throw new error_middleware_1.AppError(401, 'EXPIRED_TOKEN', 'Refresh token has expired');
        }
        // 3. Find user
        const user = await database_1.default.user.findUnique({
            where: { id: decoded.userId },
        });
        if (!user || !user.isActive) {
            throw new error_middleware_1.AppError(401, 'UNAUTHORIZED', 'User not found or inactive');
        }
        // 4. Generate new tokens
        const payload = {
            userId: user.id,
            email: user.email,
            role: user.role,
        };
        const accessToken = (0, jwt_1.generateAccessToken)(payload);
        const newRefreshToken = (0, jwt_1.generateRefreshToken)(payload);
        // Update in database (rotate refresh token)
        const expiresAt = refreshTokenExpiresAt();
        await database_1.default.refreshToken.delete({
            where: { token },
        });
        await database_1.default.refreshToken.create({
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
    async logout(token) {
        try {
            await database_1.default.refreshToken.delete({
                where: { token },
            });
        }
        catch {
            // Fail silently if token is already deleted or not found
        }
    }
    /**
     * Sends a password reset link to the user's email.
     */
    async requestPasswordReset(input) {
        const user = await database_1.default.user.findUnique({
            where: { email: input.email },
        });
        if (!user) {
            throw new error_middleware_1.AppError(404, 'USER_NOT_FOUND', 'Email tidak terdaftar');
        }
        if (!user.isActive) {
            throw new error_middleware_1.AppError(403, 'FORBIDDEN', 'Akun tidak aktif. Hubungi administrator.');
        }
        const method = resolvePasswordResetMethod(input.client);
        if (method === 'demo') {
            if (!env_1.env.PASSWORD_RESET_DEMO_CODE) {
                throw new error_middleware_1.AppError(400, 'DEMO_RESET_DISABLED', 'Reset password demo tidak tersedia. Hubungi administrator.');
            }
            return {
                email: user.email,
                method: 'demo',
                message: 'Kode verifikasi telah dikirim. Gunakan kode demo untuk melanjutkan reset password.',
            };
        }
        const rawToken = (0, reset_token_1.generateResetToken)();
        const tokenHash = (0, reset_token_1.hashResetToken)(rawToken);
        const expiresAt = new Date(Date.now() + PASSWORD_RESET_EXPIRY_MS);
        await database_1.default.passwordResetToken.deleteMany({
            where: {
                userId: user.id,
                usedAt: null,
            },
        });
        await database_1.default.passwordResetToken.create({
            data: {
                userId: user.id,
                tokenHash,
                expiresAt,
            },
        });
        const resetUrl = `${env_1.env.RESET_PASSWORD_URL}${rawToken}`;
        await (0, email_service_1.sendPasswordResetEmail)({
            to: user.email,
            fullName: user.fullName,
            resetUrl,
        });
        return {
            email: user.email,
            method: 'email',
            message: 'Link reset password telah dikirim ke email Anda. Periksa kotak masuk Gmail Anda.',
        };
    }
    /**
     * Validates whether a password reset token is still usable.
     */
    async validateResetToken(token) {
        const tokenHash = (0, reset_token_1.hashResetToken)(token);
        const savedToken = await database_1.default.passwordResetToken.findUnique({
            where: { tokenHash },
        });
        const valid = !!savedToken &&
            savedToken.usedAt == null &&
            savedToken.expiresAt > new Date();
        return { valid };
    }
    /**
     * Resets password using a one-time token from the reset email link.
     */
    async resetPassword(input) {
        if (isTokenResetInput(input)) {
            return this.resetPasswordWithToken(input);
        }
        return this.resetPasswordWithDemoCode(input);
    }
    async resetPasswordWithToken(input) {
        if (input.newPassword !== input.confirmPassword) {
            throw new error_middleware_1.AppError(400, 'PASSWORD_MISMATCH', 'Konfirmasi password tidak sesuai');
        }
        const tokenHash = (0, reset_token_1.hashResetToken)(input.token);
        const savedToken = await database_1.default.passwordResetToken.findUnique({
            where: { tokenHash },
            include: { user: true },
        });
        if (!savedToken || savedToken.usedAt != null || savedToken.expiresAt < new Date()) {
            throw new error_middleware_1.AppError(400, 'INVALID_TOKEN', 'Link reset password tidak valid atau sudah kedaluwarsa');
        }
        const user = savedToken.user;
        if (!user.isActive) {
            throw new error_middleware_1.AppError(403, 'FORBIDDEN', 'Akun tidak aktif. Hubungi administrator.');
        }
        const hashed = await (0, hash_1.hashPassword)(input.newPassword);
        await database_1.default.$transaction([
            database_1.default.user.update({
                where: { id: user.id },
                data: { passwordHash: hashed },
            }),
            database_1.default.passwordResetToken.update({
                where: { id: savedToken.id },
                data: { usedAt: new Date() },
            }),
            database_1.default.refreshToken.deleteMany({
                where: { userId: user.id },
            }),
        ]);
        return {
            email: user.email,
            message: 'Password berhasil diperbarui',
        };
    }
    async resetPasswordWithDemoCode(input) {
        if (!env_1.env.PASSWORD_RESET_DEMO_CODE) {
            throw new error_middleware_1.AppError(400, 'DEMO_RESET_DISABLED', 'Reset password demo tidak tersedia');
        }
        if (input.code !== env_1.env.PASSWORD_RESET_DEMO_CODE) {
            throw new error_middleware_1.AppError(400, 'INVALID_CODE', 'Kode verifikasi salah');
        }
        const user = await database_1.default.user.findUnique({
            where: { email: input.email },
        });
        if (!user) {
            throw new error_middleware_1.AppError(404, 'USER_NOT_FOUND', 'Email tidak terdaftar');
        }
        if (!user.isActive) {
            throw new error_middleware_1.AppError(403, 'FORBIDDEN', 'Akun tidak aktif. Hubungi administrator.');
        }
        const hashed = await (0, hash_1.hashPassword)(input.newPassword);
        await database_1.default.$transaction([
            database_1.default.user.update({
                where: { id: user.id },
                data: { passwordHash: hashed },
            }),
            database_1.default.refreshToken.deleteMany({
                where: { userId: user.id },
            }),
        ]);
        return {
            email: user.email,
            message: 'Password berhasil diperbarui',
        };
    }
}
exports.AuthService = AuthService;
exports.default = AuthService;
