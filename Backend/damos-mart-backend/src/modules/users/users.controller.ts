import { Request, Response, NextFunction } from 'express';
import { AppError } from '../../middlewares/error.middleware';
import { UsersService } from './users.service';

const usersService = new UsersService();

export class UsersController {
  /**
   * HTTP handler to fetch profile of logged-in student.
   */
  async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const user = await usersService.getMe(userId);
      return res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to update profile details.
   */
  async updateMe(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      let avatarUrl: string | undefined;

      if (req.file) {
        avatarUrl = `/uploads/avatars/${req.file.filename}`;
      }

      const user = await usersService.updateMe(userId, req.body, avatarUrl);

      return res.status(200).json({
        success: true,
        data: user,
        message: 'Profile updated successfully',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to change account password.
   */
  async changePassword(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { currentPassword, newPassword } = req.body;

      if (!currentPassword || !newPassword) {
        return next(
          new AppError(400, 'VALIDATION_ERROR', 'Current and new password are required')
        );
      }

      await usersService.changePassword(userId, currentPassword, newPassword);

      return res.status(200).json({
        success: true,
        message: 'Password changed successfully',
      });
    } catch (error) {
      return next(error);
    }
  }

  // ==========================================
  // ADMIN HANDLERS
  // ==========================================

  /**
   * Admin: List users.
   */
  async getAdminUsers(req: Request, res: Response, next: NextFunction) {
    try {
      const { search, page, limit } = req.query as any;
      const result = await usersService.getAllUsers({
        search,
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
      });

      return res.status(200).json({
        success: true,
        data: result.users,
        pagination: result.pagination,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Get user stats & totals.
   */
  async getAdminUserDetails(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const details = await usersService.getUserDetailsAdmin(id);
      return res.status(200).json({
        success: true,
        data: details,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Toggle student active state.
   */
  async toggleUserActive(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const user = await usersService.toggleUserActive(id);
      return res.status(200).json({
        success: true,
        data: user,
        message: 'User status updated successfully',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default UsersController;
