import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { env } from '../config/env';

let io: Server;

function socketCorsOrigins(): string | string[] {
  if (env.CORS_ORIGINS.includes('*')) {
    return '*';
  }
  return env.CORS_ORIGINS;
}

/**
 * Initializes Socket.IO with namespaces for /queues and /chat
 */
export const initSocket = (server: HttpServer) => {
  const origins = socketCorsOrigins();

  io = new Server(server, {
    cors: {
      origin: origins,
      credentials: origins !== '*',
    },
  });

  // ==========================================
  // QUEUES NAMESPACE
  // ==========================================
  const queuesNamespace = io.of('/queues');
  
  queuesNamespace.on('connection', (socket: Socket) => {
    console.log(`🔌 Client connected to /queues: ${socket.id}`);
    
    // Client joins room for their own queue updates
    socket.on('queue:subscribe', (data: { userId: string }) => {
      if (data && data.userId) {
        socket.join(`user:${data.userId}`);
        console.log(`👤 User ${data.userId} subscribed to queue updates in socket ${socket.id}`);
      }
    });

    // Admin panel monitor — receives all queue events without exposing them to students
    socket.on('queue:admin-subscribe', () => {
      socket.join('admin:queues');
      console.log(`👨‍💼 Admin subscribed to queue monitor in socket ${socket.id}`);
    });

    socket.on('disconnect', () => {
      console.log(`🔌 Client disconnected from /queues: ${socket.id}`);
    });
  });

  // ==========================================
  // COMPLAINTS NAMESPACE
  // ==========================================
  const complaintsNamespace = io.of('/complaints');

  complaintsNamespace.on('connection', (socket: Socket) => {
    console.log(`🔌 Client connected to /complaints: ${socket.id}`);

    socket.on('complaint:subscribe', (data: { userId: string }) => {
      if (data && data.userId) {
        socket.join(`user:${data.userId}`);
        console.log(`📋 User ${data.userId} subscribed to complaint updates in socket ${socket.id}`);
      }
    });

    socket.on('disconnect', () => {
      console.log(`🔌 Client disconnected from /complaints: ${socket.id}`);
    });
  });

  // ==========================================
  // CHAT NAMESPACE
  // ==========================================
  const chatNamespace = io.of('/chat');

  chatNamespace.on('connection', (socket: Socket) => {
    console.log(`🔌 Client connected to /chat: ${socket.id}`);

    // Client joins chat room
    socket.on('chat:join', (data: { roomId: string }) => {
      if (data && data.roomId) {
        socket.join(`room:${data.roomId}`);
        console.log(`💬 Socket ${socket.id} joined room:${data.roomId}`);
      }
    });

    // Client sends message
    socket.on('chat:send', (data: { roomId: string; message: string; senderId: string }) => {
      if (data && data.roomId) {
        chatNamespace.to(`room:${data.roomId}`).emit('chat:message', data);
      }
    });

    // Client typing indicator
    socket.on('chat:typing', (data: { roomId: string; userId: string; isTyping: boolean }) => {
      if (data && data.roomId) {
        socket.to(`room:${data.roomId}`).emit('chat:typing', data);
      }
    });

    socket.on('disconnect', () => {
      console.log(`🔌 Client disconnected from /chat: ${socket.id}`);
    });
  });

  return io;
};

/**
 * Gets the current Socket.IO instance.
 */
export const getIo = () => io;

/**
 * Broadcasts queue position / status update to student and general monitor.
 */
export const emitQueueUpdate = (userId: string, data: any) => {
  if (io) {
    const ns = io.of('/queues');
    ns.to(`user:${userId}`).emit('queue:updated', { ...data, userId });
    ns.to('admin:queues').emit('queue:updated', { ...data, userId });
  }
};

/**
 * Broadcasts queue called event (e.g. buzzer sound in client).
 */
export const emitQueueCalled = (userId: string, data: any) => {
  if (io) {
    const ns = io.of('/queues');
    ns.to(`user:${userId}`).emit('queue:called', { ...data, userId });
    ns.to('admin:queues').emit('queue:called', { ...data, userId });
  }
};

/**
 * Broadcasts queue ready event (notifying that items are ready for pickup).
 */
export const emitQueueReady = (userId: string, data: any) => {
  if (io) {
    const ns = io.of('/queues');
    ns.to(`user:${userId}`).emit('queue:ready', { ...data, userId });
    ns.to('admin:queues').emit('queue:ready', { ...data, userId });
  }
};

/**
 * Emits chat message to a specific room and broadcasts update to admin general room.
 */
export const emitChatMessage = (roomId: string, data: any) => {
  if (io) {
    io.of('/chat').to(`room:${roomId}`).emit('chat:message', data);
    // Broadcast to admins watching the room list
    io.of('/chat').emit('chat:message_admin', data);
  }
};

/**
 * Emits chat read event.
 */
export const emitChatRead = (roomId: string, data: any) => {
  if (io) {
    io.of('/chat').to(`room:${roomId}`).emit('chat:read', data);
    io.of('/chat').emit('chat:read_admin', data);
  }
};

/**
 * Broadcasts notification of new orders to the general namespace (for admins).
 */
export const emitNewOrderAdmin = (order: any) => {
  if (io) {
    io.emit('order:new', order);
  }
};

/**
 * Notifies a student that their complaint status or admin response changed.
 */
export const emitComplaintUpdate = (userId: string, data: any) => {
  if (io) {
    io.of('/complaints').to(`user:${userId}`).emit('complaint:updated', data);
  }
};

/**
 * Notifies a student when admin manually updates their order status.
 */
export const emitOrderStatusUpdate = (userId: string, data: any) => {
  if (io) {
    io.of('/queues').to(`user:${userId}`).emit('order:status_updated', { ...data, userId });
  }
};

/**
 * Pushes a persisted in-app notification to the student's device (for local push).
 */
export const emitUserNotification = (
  userId: string,
  data: {
    id?: string;
    title: string;
    body: string;
    type: string;
    referenceId?: string | null;
  },
) => {
  if (io) {
    io.of('/queues').to(`user:${userId}`).emit('notification:new', data);
  }
};
