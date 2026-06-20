import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';
import { hashPassword, comparePassword } from '../../utils/hash';

export class UsersService {
  /**
   * Helper to strip secret credentials.
   */
  private sanitizeUser(user: any) {
    if (!user) return null;
    const { passwordHash, ...sanitized } = user;
    return sanitized;
  }

  /**
   * Fetches user profile.
   */
  async getMe(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User profile not found');
    }
    return this.sanitizeUser(user);
  }

  /**
   * Updates user details.
   */
  async updateMe(userId: string, data: { fullName?: string; phone?: string }, avatarUrl?: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User profile not found');
    }

    const updated = await prisma.user.update({
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
  async changePassword(userId: string, current: string, newPass: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User profile not found');
    }

    const isMatch = await comparePassword(current, user.passwordHash);
    if (!isMatch) {
      throw new AppError(400, 'INCORRECT_PASSWORD', 'Current password is incorrect');
    }

    const hashed = await hashPassword(newPass);

    await prisma.user.update({
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
  async getAllUsers(filters: { search?: string; page: number; limit: number }) {
    const { search, page, limit } = filters;
    const offset = (page - 1) * limit;

    const where: any = {
      role: 'STUDENT',
    };

    if (search) {
      where.OR = [
        { fullName: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, totalItems] = await Promise.all([
      prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
      }),
      prisma.user.count({ where }),
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
  async getUserDetailsAdmin(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User not found');
    }

    // Fetch order counts and totals
    const orderCount = await prisma.order.count({
      where: { userId },
    });

    const totalSpentAggregation = await prisma.order.aggregate({
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
  async toggleUserActive(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User not found');
    }

    if (user.role === 'ADMIN') {
      throw new AppError(400, 'BAD_REQUEST', 'Cannot toggle active status of administrator');
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        isActive: !user.isActive,
      },
    });

    // Invalidate refresh tokens if user is disabled
    if (!updated.isActive) {
      await prisma.refreshToken.deleteMany({
        where: { userId },
      });
    }

    return this.sanitizeUser(updated);
  }
}
export default UsersService;
