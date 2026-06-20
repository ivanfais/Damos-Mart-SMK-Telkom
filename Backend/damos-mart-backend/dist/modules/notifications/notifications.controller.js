"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsController = void 0;
const notifications_service_1 = require("./notifications.service");
const notificationsService = new notifications_service_1.NotificationsService();
class NotificationsController {
    /**
     * HTTP handler to fetch student's notifications history and count.
     */
    async getNotifications(req, res, next) {
        try {
            const userId = req.user.userId;
            const data = await notificationsService.getNotifications(userId);
            return res.status(200).json({
                success: true,
                data: data.notifications,
                unreadCount: data.unreadCount,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP handler to mark a notification as read.
     */
    async readNotification(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            const notification = await notificationsService.markAsRead(userId, id);
            return res.status(200).json({
                success: true,
                data: notification,
                message: 'Notification marked as read',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP handler to mark all user's notifications as read.
     */
    async readAllNotifications(req, res, next) {
        try {
            const userId = req.user.userId;
            await notificationsService.markAllAsRead(userId);
            return res.status(200).json({
                success: true,
                message: 'All notifications marked as read',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.NotificationsController = NotificationsController;
exports.default = NotificationsController;
