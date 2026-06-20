import { Request, Response, NextFunction } from 'express';
import { NotificationsService } from './notifications.service';

const notificationsService = new NotificationsService();

export class NotificationsController {
  /**
   * HTTP handler to fetch student's notifications history and count.
   */
  async getNotifications(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const data = await notificationsService.getNotifications(userId);
      return res.status(200).json({
        success: true,
        data: data.notifications,
        unreadCount: data.unreadCount,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to mark a notification as read.
   */
  async readNotification(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { id } = req.params;

      const notification = await notificationsService.markAsRead(userId, id);

      return res.status(200).json({
        success: true,
        data: notification,
        message: 'Notification marked as read',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to mark all user's notifications as read.
   */
  async readAllNotifications(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      await notificationsService.markAllAsRead(userId);
      return res.status(200).json({
        success: true,
        message: 'All notifications marked as read',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default NotificationsController;
