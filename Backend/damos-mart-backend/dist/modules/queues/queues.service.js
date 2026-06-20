"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.QueuesService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
const socket_1 = require("../../socket");
class QueuesService {
    /**
     * Fetches active queues belonging to the student (WAITING, PREPARING, READY).
     */
    async getActiveQueues(userId) {
        return database_1.default.queue.findMany({
            where: {
                userId,
                status: { in: ['WAITING', 'PREPARING', 'READY'] },
            },
            include: {
                order: {
                    include: {
                        orderItems: true,
                    },
                },
            },
            orderBy: { queueNumber: 'asc' },
        });
    }
    /**
     * Gets details of a queue by ID.
     */
    async getQueueById(userId, queueId) {
        const queue = await database_1.default.queue.findUnique({
            where: { id: queueId },
            include: {
                order: {
                    include: {
                        orderItems: true,
                    },
                },
            },
        });
        if (!queue || (queue.userId !== userId && userId !== 'ADMIN')) {
            throw new error_middleware_1.AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
        }
        // QR data generated as the queue ID (scannable by admin panel scanner)
        return {
            queue,
            order: queue.order,
            qrData: queue.id,
        };
    }
    /**
     * Gets current state of queues for dashboard counters.
     * - currentServing: queue number currently status = PREPARING or READY (latest)
     * - totalWaiting: count of status = WAITING
     */
    async getCurrentQueueState() {
        const serving = await database_1.default.queue.findFirst({
            where: {
                status: { in: ['PREPARING', 'READY'] },
                queueDate: new Date(),
            },
            orderBy: { calledAt: 'desc' },
            select: { queueNumber: true },
        });
        const waitingCount = await database_1.default.queue.count({
            where: {
                status: 'WAITING',
                queueDate: new Date(),
            },
        });
        return {
            currentServing: serving?.queueNumber || 'N/A',
            totalWaiting: waitingCount,
        };
    }
    // ==========================================
    // ADMIN ACTIONS
    // ==========================================
    /**
     * Admin: Fetches all queues created today.
     */
    async getAllTodayQueues() {
        return database_1.default.queue.findMany({
            where: {
                queueDate: new Date(),
            },
            orderBy: { createdAt: 'asc' },
            include: {
                user: {
                    select: {
                        fullName: true,
                        email: true,
                    },
                },
                order: {
                    include: {
                        orderItems: true,
                    },
                },
            },
        });
    }
    /**
     * Admin: Call queue -> status = PREPARING.
     */
    async callQueue(queueId) {
        const queue = await database_1.default.queue.findUnique({
            where: { id: queueId },
        });
        if (!queue) {
            throw new error_middleware_1.AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
        }
        const updated = await database_1.default.$transaction(async (tx) => {
            // 1. Update queue status
            const uQueue = await tx.queue.update({
                where: { id: queueId },
                data: {
                    status: 'PREPARING',
                    calledAt: new Date(),
                },
            });
            // 2. Update order status
            await tx.order.update({
                where: { id: queue.orderId },
                data: { status: 'PREPARING' },
            });
            return uQueue;
        });
        // Notify student via Websockets
        (0, socket_1.emitQueueCalled)(queue.userId, {
            queueId: updated.id,
            queueNumber: updated.queueNumber,
            status: updated.status,
            message: `Nomor antrean ${updated.queueNumber} sedang dipersiapkan.`,
        });
        return updated;
    }
    /**
     * Admin: Ready queue (order is prepared and ready for pickup) -> status = READY.
     */
    async readyQueue(queueId) {
        const queue = await database_1.default.queue.findUnique({
            where: { id: queueId },
        });
        if (!queue) {
            throw new error_middleware_1.AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
        }
        const updated = await database_1.default.$transaction(async (tx) => {
            const uQueue = await tx.queue.update({
                where: { id: queueId },
                data: {
                    status: 'READY',
                },
            });
            await tx.order.update({
                where: { id: queue.orderId },
                data: { status: 'READY' },
            });
            // Add Notification row
            await tx.notification.create({
                data: {
                    userId: queue.userId,
                    title: 'Pesanan Siap Diambil',
                    body: `Pesanan Anda dengan nomor antrean ${queue.queueNumber} sudah siap diambil di kasir Damos Mart!`,
                    type: 'QUEUE_READY',
                    referenceId: queue.id,
                },
            });
            return uQueue;
        });
        // Notify student via Websockets
        (0, socket_1.emitQueueReady)(queue.userId, {
            queueId: updated.id,
            queueNumber: updated.queueNumber,
            status: updated.status,
        });
        return updated;
    }
    /**
     * Admin: Complete queue (student picked up the order) -> status = COMPLETED.
     */
    async completeQueue(queueId) {
        const queue = await database_1.default.queue.findUnique({
            where: { id: queueId },
        });
        if (!queue) {
            throw new error_middleware_1.AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
        }
        const updated = await database_1.default.$transaction(async (tx) => {
            const uQueue = await tx.queue.update({
                where: { id: queueId },
                data: {
                    status: 'COMPLETED',
                    completedAt: new Date(),
                },
            });
            await tx.order.update({
                where: { id: queue.orderId },
                data: { status: 'COMPLETED' },
            });
            return uQueue;
        });
        // Notify student via Websockets
        (0, socket_1.emitQueueUpdate)(queue.userId, {
            queueId: updated.id,
            status: updated.status,
            queueNumber: updated.queueNumber,
        });
        return updated;
    }
    /**
     * Admin: Skip queue -> status = SKIPPED.
     */
    async skipQueue(queueId) {
        const queue = await database_1.default.queue.findUnique({
            where: { id: queueId },
        });
        if (!queue) {
            throw new error_middleware_1.AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
        }
        const updated = await database_1.default.$transaction(async (tx) => {
            const uQueue = await tx.queue.update({
                where: { id: queueId },
                data: {
                    status: 'SKIPPED',
                },
            });
            // Revert order status if skipped? Standard flow: keeps READY or PREPARING status but queue is skipped. Let's set order status to PENDING or CANCELLED if skipped, or just let it stay. Let's set order status to READY or keep it. Let's keep it or map to PENDING. Let's leave order status, or mark as CANCELLED/PENDING if desired. Let's keep order status as is or update to CANCELLED depending on business logic, but let's let it remain as is, or we can just leave order status.
            return uQueue;
        });
        // Notify student via Websockets
        (0, socket_1.emitQueueUpdate)(queue.userId, {
            queueId: updated.id,
            status: updated.status,
            queueNumber: updated.queueNumber,
        });
        return updated;
    }
    /**
     * Admin: Scan QR Code containing Queue ID -> auto completes the queue.
     */
    async scanQR(qrData) {
        // qrData is the queue ID
        return this.completeQueue(qrData);
    }
}
exports.QueuesService = QueuesService;
exports.default = QueuesService;
