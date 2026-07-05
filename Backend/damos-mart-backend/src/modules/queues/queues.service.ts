import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';
import { emitQueueUpdate, emitQueueCalled, emitQueueReady, emitUserNotification } from '../../socket';

/**
 * Returns [startOfDay, endOfDay] for the current local day. Used to filter
 * `queueDate` (a @db.Date column) reliably — comparing the column with a single
 * `new Date()` timestamp never matches because the stored value is date-only.
 */
function todayRange() {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date();
  end.setHours(23, 59, 59, 999);
  return { start, end };
}

export class QueuesService {
  /**
   * Antrean aktif siswa = subset board admin hari ini (sumber data sama persis).
   */
  async getActiveQueues(userId: string) {
    const allToday = await this.getAllTodayQueues();
    return allToday
      .filter((queue) => this.isVisibleOnStudentBoard(queue, userId))
      .sort((a, b) => a.queueNumber.localeCompare(b.queueNumber));
  }

  private isVisibleOnStudentBoard(
    queue: {
      userId: string;
      status: string;
      order: {
        userId: string;
        status: string;
        paymentStatus: string;
        paymentMethod: string;
      } | null;
    },
    userId: string,
  ): boolean {
    if (queue.userId !== userId) return false;
    if (!['WAITING', 'PREPARING', 'READY'].includes(queue.status)) return false;

    const order = queue.order;
    if (!order || order.userId !== userId) return false;
    if (['COMPLETED', 'CANCELLED'].includes(order.status)) return false;
    if (order.paymentStatus === 'UNPAID' && order.paymentMethod === 'QRIS') return false;

    return true;
  }

  /**
   * Gets details of a queue by ID.
   */
  async getQueueById(userId: string, queueId: string) {
    const queue = await prisma.queue.findUnique({
      where: { id: queueId },
      include: {
        order: {
          include: {
            orderItems: {
              include: {
                product: {
                  select: { imageUrl: true },
                },
              },
            },
          },
        },
      },
    });

    if (!queue || (queue.userId !== userId && userId !== 'ADMIN')) {
      throw new AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
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
    const { start, end } = todayRange();

    const serving = await prisma.queue.findFirst({
      where: {
        status: { in: ['PREPARING', 'READY'] },
        queueDate: { gte: start, lte: end },
      },
      orderBy: { calledAt: 'desc' },
      select: { queueNumber: true },
    });

    const waitingCount = await prisma.queue.count({
      where: {
        status: 'WAITING',
        queueDate: { gte: start, lte: end },
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
    const { start, end } = todayRange();
    return prisma.queue.findMany({
      where: {
        queueDate: { gte: start, lte: end },
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
            orderItems: {
              include: {
                product: {
                  select: { imageUrl: true },
                },
              },
            },
          },
        },
      },
    });
  }

  /**
   * Admin: Call queue -> status = PREPARING.
   */
  async callQueue(queueId: string) {
    const queue = await prisma.queue.findUnique({
      where: { id: queueId },
    });

    if (!queue) {
      throw new AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
    }

    const updated = await prisma.$transaction(async (tx) => {
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
    const order = await prisma.order.findUnique({
      where: { id: queue.orderId },
      select: { orderNumber: true },
    });

    emitQueueCalled(queue.userId, {
      queueId: updated.id,
      orderId: queue.orderId,
      queueNumber: updated.queueNumber,
      orderNumber: order?.orderNumber,
      status: updated.status,
      message: `Nomor antrean ${updated.queueNumber} sedang dipersiapkan.`,
    });

    return updated;
  }

  /**
   * Admin: Ready queue (order is prepared and ready for pickup) -> status = READY.
   */
  async readyQueue(queueId: string) {
    const queue = await prisma.queue.findUnique({
      where: { id: queueId },
      include: {
        order: { select: { orderNumber: true } },
      },
    });

    if (!queue) {
      throw new AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
    }

    const updated = await prisma.$transaction(async (tx) => {
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
      const notification = await tx.notification.create({
        data: {
          userId: queue.userId,
          title: 'Pesanan Siap Diambil',
          body: `Pesanan Anda dengan nomor antrean ${queue.queueNumber} sudah siap diambil di kasir Damos Mart!`,
          type: 'QUEUE_READY',
          referenceId: queue.id,
        },
      });

      return { queue: uQueue, notification };
    });

    // Notify student via Websockets
    emitQueueReady(queue.userId, {
      queueId: updated.queue.id,
      orderId: queue.orderId,
      queueNumber: updated.queue.queueNumber,
      orderNumber: queue.order.orderNumber,
    });

    emitUserNotification(queue.userId, {
      id: updated.notification.id,
      title: updated.notification.title,
      body: updated.notification.body,
      type: updated.notification.type,
      referenceId: updated.notification.referenceId,
    });

    return updated.queue;
  }

  /**
   * Admin: Complete queue (student picked up the order) -> status = COMPLETED.
   */
  async completeQueue(queueId: string) {
    const queue = await prisma.queue.findUnique({
      where: { id: queueId },
    });

    if (!queue) {
      throw new AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
    }

    const updated = await prisma.$transaction(async (tx) => {
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
    emitQueueUpdate(queue.userId, {
      queueId: updated.id,
      orderId: queue.orderId,
      status: updated.status,
      queueNumber: updated.queueNumber,
    });

    return updated;
  }

  /**
   * Admin: Skip queue -> status = SKIPPED.
   */
  async skipQueue(queueId: string) {
    const queue = await prisma.queue.findUnique({
      where: { id: queueId },
    });

    if (!queue) {
      throw new AppError(404, 'QUEUE_NOT_FOUND', 'Queue record not found');
    }

    const updated = await prisma.$transaction(async (tx) => {
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
    emitQueueUpdate(queue.userId, {
      queueId: updated.id,
      orderId: queue.orderId,
      status: updated.status,
      queueNumber: updated.queueNumber,
    });

    return updated;
  }

  /**
   * Admin: Scan QR Code containing Queue ID -> auto completes the queue.
   */
  async scanQR(qrData: string) {
    // qrData is the queue ID
    return this.completeQueue(qrData);
  }
}
export default QueuesService;
