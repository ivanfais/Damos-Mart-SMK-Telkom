"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatController = void 0;
const chat_service_1 = require("./chat.service");
const chatService = new chat_service_1.ChatService();
class ChatController {
    /**
     * Fetches or creates the chat room of the logged-in student.
     */
    async getRoom(req, res, next) {
        try {
            const studentId = req.user.userId;
            const room = await chatService.getOrCreateRoom(studentId);
            return res.status(200).json({
                success: true,
                data: room,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches paginated messages of a room and marks them as read.
     */
    async getRoomMessages(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            const { cursor, limit } = req.query;
            const pageLimit = parseInt(limit) || 30;
            const result = await chatService.getRoomMessages(id, cursor, pageLimit);
            // Auto mark messages as read for user
            await chatService.markAsRead(id, userId);
            return res.status(200).json({
                success: true,
                data: result.messages,
                nextCursor: result.nextCursor,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Submits a message to a room.
     */
    async sendMessage(req, res, next) {
        try {
            const senderId = req.user.userId;
            const { id } = req.params;
            const { message } = req.body;
            const chatMessage = await chatService.saveMessage(senderId, id, message);
            return res.status(201).json({
                success: true,
                data: chatMessage,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    // ==========================================
    // ADMIN HANDLERS
    // ==========================================
    /**
     * Admin: List all chat rooms with last message details and unread count.
     */
    async getAdminRooms(req, res, next) {
        try {
            const adminId = req.user.userId;
            const rooms = await chatService.getAllRooms(adminId);
            return res.status(200).json({
                success: true,
                data: rooms,
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.ChatController = ChatController;
exports.default = ChatController;
