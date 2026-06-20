"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
const socket_1 = require("../../socket");
class ChatService {
    /**
     * Fetches or creates a chat room for the logged-in student.
     * There is a 1-to-1 relationship between a student and their room.
     */
    async getOrCreateRoom(studentId) {
        let room = await database_1.default.chatRoom.findUnique({
            where: { studentId },
            include: {
                student: {
                    select: {
                        id: true,
                        fullName: true,
                        avatarUrl: true,
                    },
                },
            },
        });
        if (!room) {
            room = await database_1.default.chatRoom.create({
                data: {
                    studentId,
                },
                include: {
                    student: {
                        select: {
                            id: true,
                            fullName: true,
                            avatarUrl: true,
                        },
                    },
                },
            });
        }
        return room;
    }
    /**
     * Fetches messages in a room with cursor pagination.
     */
    async getRoomMessages(roomId, cursor, limit = 30) {
        const query = {
            where: { roomId },
            orderBy: { createdAt: 'desc' },
            take: limit + 1, // Get one extra to determine next cursor
            include: {
                sender: {
                    select: {
                        id: true,
                        fullName: true,
                        avatarUrl: true,
                        role: true,
                    },
                },
            },
        };
        if (cursor) {
            query.cursor = { id: cursor };
            query.skip = 1; // Skip the cursor message itself
        }
        const messages = await database_1.default.chatMessage.findMany(query);
        let nextCursor = undefined;
        if (messages.length > limit) {
            const nextItem = messages.pop();
            nextCursor = nextItem?.id;
        }
        // Return messages in chronological order (oldest first for chat window)
        return {
            messages: messages.reverse(),
            nextCursor,
        };
    }
    /**
     * Saves and broadcasts a chat message.
     */
    async saveMessage(senderId, roomId, messageText) {
        const room = await database_1.default.chatRoom.findUnique({
            where: { id: roomId },
        });
        if (!room) {
            throw new error_middleware_1.AppError(404, 'ROOM_NOT_FOUND', 'Chat room not found');
        }
        const chatMessage = await database_1.default.$transaction(async (tx) => {
            // 1. Create message
            const msg = await tx.chatMessage.create({
                data: {
                    roomId,
                    senderId,
                    message: messageText,
                    isRead: false,
                },
                include: {
                    sender: {
                        select: {
                            id: true,
                            fullName: true,
                            avatarUrl: true,
                            role: true,
                        },
                    },
                },
            });
            // 2. Update room fields
            await tx.chatRoom.update({
                where: { id: roomId },
                data: {
                    lastMessage: messageText,
                    lastMessageAt: new Date(),
                },
            });
            return msg;
        });
        // Broadcast message via socket to members in the room
        (0, socket_1.emitChatMessage)(roomId, chatMessage);
        return chatMessage;
    }
    /**
     * Marks all messages in a room as read by the user (other than their own).
     */
    async markAsRead(roomId, userId) {
        await database_1.default.chatMessage.updateMany({
            where: {
                roomId,
                senderId: { not: userId },
                isRead: false,
            },
            data: {
                isRead: true,
            },
        });
        (0, socket_1.emitChatRead)(roomId, { readBy: userId });
    }
    // ==========================================
    // ADMIN METHODS
    // ==========================================
    /**
     * Admin: Get all chat rooms sorted by lastMessageAt, including student info and unread count.
     */
    async getAllRooms(adminId) {
        const rooms = await database_1.default.chatRoom.findMany({
            orderBy: {
                lastMessageAt: 'desc',
            },
            include: {
                student: {
                    select: {
                        id: true,
                        fullName: true,
                        avatarUrl: true,
                    },
                },
                messages: {
                    orderBy: { createdAt: 'desc' },
                    take: 1, // To ensure we have the absolute latest details if needed
                },
            },
        });
        // Map rooms and fetch unread count for each room
        const roomsWithStats = await Promise.all(rooms.map(async (room) => {
            const unreadCount = await database_1.default.chatMessage.count({
                where: {
                    roomId: room.id,
                    senderId: { not: adminId }, // Count messages sent by students
                    isRead: false,
                },
            });
            return {
                id: room.id,
                studentId: room.studentId,
                studentName: room.student.fullName,
                studentAvatar: room.student.avatarUrl,
                lastMessage: room.lastMessage,
                lastMessageAt: room.lastMessageAt,
                unreadCount,
            };
        }));
        return roomsWithStats;
    }
}
exports.ChatService = ChatService;
exports.default = ChatService;
