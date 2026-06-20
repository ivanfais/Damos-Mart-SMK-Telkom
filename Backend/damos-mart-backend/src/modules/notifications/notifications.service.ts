import prisma from '../../config/database';

export class NotificationsService {
  /**
   * Fetches user notifications and computes unread count.
   */
  async getNotifications(userId: string) {
    const [notifications, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.notification.count({
        where: { userId, isRead: false },
      }),
    ]);

    return {
      notifications,
      unreadCount,
    };
  }

  /**
   * Marks a specific notification as read.
   */
  async markAsRead(userId: string, id: string) {
    return prisma.notification.update({
      where: { id, userId },
      data: { isRead: true },
    });
  }

  /**
   * Marks all notifications of the user as read.
   */
  async markAllAsRead(userId: string) {
    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }
}
export default NotificationsService;
