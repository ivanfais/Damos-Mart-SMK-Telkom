"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.emitUserNotification = exports.emitOrderStatusUpdate = exports.emitComplaintUpdate = exports.emitNewOrderAdmin = exports.emitChatRead = exports.emitChatMessage = exports.emitQueueReady = exports.emitQueueCalled = exports.emitQueueUpdate = exports.getIo = exports.initSocket = void 0;
const socket_io_1 = require("socket.io");
const env_1 = require("../config/env");
let io;
function socketCorsOrigins() {
    if (env_1.env.CORS_ORIGINS.includes('*')) {
        return '*';
    }
    return env_1.env.CORS_ORIGINS;
}
/**
 * Initializes Socket.IO with namespaces for /queues and /chat
 */
const initSocket = (server) => {
    const origins = socketCorsOrigins();
    io = new socket_io_1.Server(server, {
        cors: {
            origin: origins,
            credentials: origins !== '*',
        },
    });
    // ==========================================
    // QUEUES NAMESPACE
    // ==========================================
    const queuesNamespace = io.of('/queues');
    queuesNamespace.on('connection', (socket) => {
        console.log(`🔌 Client connected to /queues: ${socket.id}`);
        // Client joins room for their own queue updates
        socket.on('queue:subscribe', (data) => {
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
    complaintsNamespace.on('connection', (socket) => {
        console.log(`🔌 Client connected to /complaints: ${socket.id}`);
        socket.on('complaint:subscribe', (data) => {
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
    chatNamespace.on('connection', (socket) => {
        console.log(`🔌 Client connected to /chat: ${socket.id}`);
        // Client joins chat room
        socket.on('chat:join', (data) => {
            if (data && data.roomId) {
                socket.join(`room:${data.roomId}`);
                console.log(`💬 Socket ${socket.id} joined room:${data.roomId}`);
            }
        });
        // Client sends message
        socket.on('chat:send', (data) => {
            if (data && data.roomId) {
                chatNamespace.to(`room:${data.roomId}`).emit('chat:message', data);
            }
        });
        // Client typing indicator
        socket.on('chat:typing', (data) => {
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
exports.initSocket = initSocket;
/**
 * Gets the current Socket.IO instance.
 */
const getIo = () => io;
exports.getIo = getIo;
/**
 * Broadcasts queue position / status update to student and general monitor.
 */
const emitQueueUpdate = (userId, data) => {
    if (io) {
        const ns = io.of('/queues');
        ns.to(`user:${userId}`).emit('queue:updated', { ...data, userId });
        ns.to('admin:queues').emit('queue:updated', { ...data, userId });
    }
};
exports.emitQueueUpdate = emitQueueUpdate;
/**
 * Broadcasts queue called event (e.g. buzzer sound in client).
 */
const emitQueueCalled = (userId, data) => {
    if (io) {
        const ns = io.of('/queues');
        ns.to(`user:${userId}`).emit('queue:called', { ...data, userId });
        ns.to('admin:queues').emit('queue:called', { ...data, userId });
    }
};
exports.emitQueueCalled = emitQueueCalled;
/**
 * Broadcasts queue ready event (notifying that items are ready for pickup).
 */
const emitQueueReady = (userId, data) => {
    if (io) {
        const ns = io.of('/queues');
        ns.to(`user:${userId}`).emit('queue:ready', { ...data, userId });
        ns.to('admin:queues').emit('queue:ready', { ...data, userId });
    }
};
exports.emitQueueReady = emitQueueReady;
/**
 * Emits chat message to a specific room and broadcasts update to admin general room.
 */
const emitChatMessage = (roomId, data) => {
    if (io) {
        io.of('/chat').to(`room:${roomId}`).emit('chat:message', data);
        // Broadcast to admins watching the room list
        io.of('/chat').emit('chat:message_admin', data);
    }
};
exports.emitChatMessage = emitChatMessage;
/**
 * Emits chat read event.
 */
const emitChatRead = (roomId, data) => {
    if (io) {
        io.of('/chat').to(`room:${roomId}`).emit('chat:read', data);
        io.of('/chat').emit('chat:read_admin', data);
    }
};
exports.emitChatRead = emitChatRead;
/**
 * Broadcasts notification of new orders to the general namespace (for admins).
 */
const emitNewOrderAdmin = (order) => {
    if (io) {
        io.emit('order:new', order);
    }
};
exports.emitNewOrderAdmin = emitNewOrderAdmin;
/**
 * Notifies a student that their complaint status or admin response changed.
 */
const emitComplaintUpdate = (userId, data) => {
    if (io) {
        io.of('/complaints').to(`user:${userId}`).emit('complaint:updated', data);
    }
};
exports.emitComplaintUpdate = emitComplaintUpdate;
/**
 * Notifies a student when admin manually updates their order status.
 */
const emitOrderStatusUpdate = (userId, data) => {
    if (io) {
        io.of('/queues').to(`user:${userId}`).emit('order:status_updated', { ...data, userId });
    }
};
exports.emitOrderStatusUpdate = emitOrderStatusUpdate;
/**
 * Pushes a persisted in-app notification to the student's device (for local push).
 */
const emitUserNotification = (userId, data) => {
    if (io) {
        io.of('/queues').to(`user:${userId}`).emit('notification:new', data);
    }
};
exports.emitUserNotification = emitUserNotification;
