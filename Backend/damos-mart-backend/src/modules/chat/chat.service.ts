import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';
import { emitChatMessage, emitChatRead } from '../../socket';

export class ChatService {
  /**
   * Fetches or creates a chat room for the logged-in student.
   * There is a 1-to-1 relationship between a student and their room.
   */
  async getOrCreateRoom(studentId: string) {
    let room = await prisma.chatRoom.findUnique({
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
      room = await prisma.chatRoom.create({
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
  async getRoomMessages(roomId: string, cursor?: string, limit = 30) {
    const query: any = {
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

    const messages = await prisma.chatMessage.findMany(query);

    let nextCursor: string | undefined = undefined;
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
  async saveMessage(senderId: string, roomId: string, messageText: string) {
    const room = await prisma.chatRoom.findUnique({
      where: { id: roomId },
    });

    if (!room) {
      throw new AppError(404, 'ROOM_NOT_FOUND', 'Chat room not found');
    }

    const chatMessage = await prisma.$transaction(async (tx) => {
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
    emitChatMessage(roomId, chatMessage);

    return chatMessage;
  }

  /**
   * Marks all messages in a room as read by the user (other than their own).
   */
  async markAsRead(roomId: string, userId: string) {
    await prisma.chatMessage.updateMany({
      where: {
        roomId,
        senderId: { not: userId },
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });

    emitChatRead(roomId, { readBy: userId });
  }

  // ==========================================
  // ADMIN METHODS
  // ==========================================

  /**
   * Admin: Get all chat rooms sorted by lastMessageAt, including student info and unread count.
   */
  async getAllRooms(adminId: string) {
    const rooms = await prisma.chatRoom.findMany({
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
    const roomsWithStats = await Promise.all(
      rooms.map(async (room) => {
        const unreadCount = await prisma.chatMessage.count({
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
      })
    );

    return roomsWithStats;
  }
}
export default ChatService;
