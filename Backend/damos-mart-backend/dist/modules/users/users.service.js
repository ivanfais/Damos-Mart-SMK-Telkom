"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
const hash_1 = require("../../utils/hash");
class UsersService {
    /**
     * Helper to strip secret credentials.
     */
    sanitizeUser(user) {
        if (!user)
            return null;
        const { passwordHash, ...sanitized } = user;
        return sanitized;
    }
    /**
     * Fetches user profile.
     */
    async getMe(userId) {
        const user = await database_1.default.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            throw new error_middleware_1.AppError(404, 'USER_NOT_FOUND', 'User profile not found');
        }
        return this.sanitizeUser(user);
    }
    /**
     * Updates user details.
     */
    async updateMe(userId, data, avatarUrl) {
        const user = await database_1.default.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            throw new error_middleware_1.AppError(404, 'USER_NOT_FOUND', 'User profile not found');
        }
        const updated = await database_1.default.user.update({
            where: { id: userId },
            data: {
                fullName: data.fullName || user.fullName,
                phone: data.phone !== undefined ? data.phone : user.phone,
                avatarUrl: avatarUrl || user.avatarUrl,
            },
        });
        return this.sanitizeUser(updated);
    }
    /**
     * Changes account password.
     */
    async changePassword(userId, current, newPass) {
        const user = await database_1.default.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            throw new error_middleware_1.AppError(404, 'USER_NOT_FOUND', 'User profile not found');
        }
        const isMatch = await (0, hash_1.comparePassword)(current, user.passwordHash);
        if (!isMatch) {
            throw new error_middleware_1.AppError(400, 'INCORRECT_PASSWORD', 'Current password is incorrect');
        }
        const hashed = await (0, hash_1.hashPassword)(newPass);
        await database_1.default.user.update({
            where: { id: userId },
            data: { passwordHash: hashed },
        });
    }
    // ==========================================
    // ADMIN METHODS FOR USERS
    // ==========================================
    /**
     * Admin: List users (students) with pagination and filters.
     */
    async getAllUsers(filters) {
        const { search, page, limit } = filters;
        const offset = (page - 1) * limit;
        const where = {
            role: 'STUDENT',
        };
        if (search) {
            where.OR = [
                { fullName: { contains: search, mode: 'insensitive' } },
                { email: { contains: search, mode: 'insensitive' } },
            ];
        }
        const [users, totalItems] = await Promise.all([
            database_1.default.user.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip: offset,
                take: limit,
            }),
            database_1.default.user.count({ where }),
        ]);
        const formattedUsers = users.map((u) => this.sanitizeUser(u));
        const totalPages = Math.ceil(totalItems / limit) || 1;
        const pagination = { page, limit, totalItems, totalPages };
        return {
            users: formattedUsers,
            pagination,
        };
    }
    /**
     * Admin: Fetch detailed statistics for a user.
     */
    async getUserDetailsAdmin(userId) {
        const user = await database_1.default.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            throw new error_middleware_1.AppError(404, 'USER_NOT_FOUND', 'User not found');
        }
        // Fetch order counts and totals
        const orderCount = await database_1.default.order.count({
            where: { userId },
        });
        const totalSpentAggregation = await database_1.default.order.aggregate({
            where: { userId, paymentStatus: 'PAID' },
            _sum: { total: true },
        });
        const totalSpent = Number(totalSpentAggregation._sum.total || 0);
        return {
            user: this.sanitizeUser(user),
            orderCount,
            totalSpent,
        };
    }
    /**
     * Admin: Toggle student active/inactive.
     */
    async toggleUserActive(userId) {
        const user = await database_1.default.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            throw new error_middleware_1.AppError(404, 'USER_NOT_FOUND', 'User not found');
        }
        if (user.role === 'ADMIN') {
            throw new error_middleware_1.AppError(400, 'BAD_REQUEST', 'Cannot toggle active status of administrator');
        }
        const updated = await database_1.default.user.update({
            where: { id: userId },
            data: {
                isActive: !user.isActive,
            },
        });
        // Invalidate refresh tokens if user is disabled
        if (!updated.isActive) {
            await database_1.default.refreshToken.deleteMany({
                where: { userId },
            });
        }
        return this.sanitizeUser(updated);
    }
}
exports.UsersService = UsersService;
exports.default = UsersService;
