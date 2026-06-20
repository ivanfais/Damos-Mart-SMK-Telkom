"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsService = void 0;
const database_1 = __importDefault(require("../../config/database"));
class NotificationsService {
    /**
     * Fetches user notifications and computes unread count.
     */
    async getNotifications(userId) {
        const [notifications, unreadCount] = await Promise.all([
            database_1.default.notification.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
            }),
            database_1.default.notification.count({
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
    async markAsRead(userId, id) {
        return database_1.default.notification.update({
            where: { id, userId },
            data: { isRead: true },
        });
    }
    /**
     * Marks all notifications of the user as read.
     */
    async markAllAsRead(userId) {
        await database_1.default.notification.updateMany({
            where: { userId, isRead: false },
            data: { isRead: true },
        });
    }
}
exports.NotificationsService = NotificationsService;
exports.default = NotificationsService;
