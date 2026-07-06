"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
const pagination_1 = require("../../utils/pagination");
const order_number_1 = require("../../utils/order-number");
const queue_number_1 = require("../../utils/queue-number");
const socket_1 = require("../../socket");
class OrdersService {
    /**
     * Creates an order from selected cart items. Status starts as PENDING (unpaid).
     */
    async createOrder(userId, data) {
        // 1. Fetch selected cart items
        const cartItems = await database_1.default.cartItem.findMany({
            where: {
                id: { in: data.cartItemIds },
                userId,
            },
            include: {
                product: true,
                variant: true,
            },
        });
        if (cartItems.length === 0) {
            throw new error_middleware_1.AppError(404, 'CART_ITEMS_NOT_FOUND', 'Selected cart items not found or do not belong to you');
        }
        // 2. Validate stock & preorder status, and compute price
        let subtotal = 0;
        let containsPreorder = false;
        for (const item of cartItems) {
            const isPreorder = item.product.isPreorder;
            if (isPreorder) {
                containsPreorder = true;
            }
            // Check stock for all items (including pre-order quota).
            const availableStock = item.variant ? item.variant.stock : item.product.stock;
            if (item.quantity > availableStock) {
                throw new error_middleware_1.AppError(400, 'INSUFFICIENT_STOCK', `Insufficient stock for product: ${item.product.name}${item.variant ? ` (Variant: ${item.variant.variantName})` : ''}. Available stock: ${availableStock}`);
            }
            // Price calculation
            const productPrice = Number(item.product.price);
            const additionalPrice = item.variant ? Number(item.variant.additionalPrice) : 0;
            subtotal += (productPrice + additionalPrice) * item.quantity;
        }
        const total = subtotal; // No tax/delivery specified in Damos Mart
        const orderNumber = await (0, order_number_1.generateNextOrderNumber)(database_1.default);
        // 3. Run db transaction to create order
        const resultOrder = await database_1.default.$transaction(async (tx) => {
            // Create Order
            const order = await tx.order.create({
                data: {
                    userId,
                    orderNumber,
                    status: 'PENDING',
                    isPreorder: containsPreorder,
                    subtotal,
                    total,
                    paymentMethod: data.paymentMethod,
                    paymentStatus: 'UNPAID',
                    notes: data.notes,
                },
            });
            // Create Order Items
            const orderItemsData = cartItems.map((item) => {
                const productPrice = Number(item.product.price);
                const additionalPrice = item.variant ? Number(item.variant.additionalPrice) : 0;
                const unitPrice = productPrice + additionalPrice;
                return {
                    orderId: order.id,
                    productId: item.productId,
                    variantId: item.variantId,
                    productName: item.product.name,
                    variantName: item.variant ? item.variant.variantName : null,
                    productPrice: unitPrice,
                    quantity: item.quantity,
                    subtotal: unitPrice * item.quantity,
                };
            });
            await tx.orderItem.createMany({
                data: orderItemsData,
            });
            const queueNumber = await (0, queue_number_1.generateNextQueueNumber)(tx);
            await tx.queue.create({
                data: {
                    orderId: order.id,
                    userId,
                    queueNumber,
                    queueDate: new Date(),
                    status: 'WAITING',
                },
            });
            return tx.order.findUnique({
                where: { id: order.id },
                include: {
                    orderItems: {
                        include: {
                            product: {
                                select: {
                                    imageUrl: true,
                                    category: { select: { name: true } },
                                },
                            },
                        },
                    },
                    queue: true,
                },
            });
        });
        if (!resultOrder) {
            throw new error_middleware_1.AppError(500, 'ORDER_CREATE_FAILED', 'Failed to create order');
        }
        // Notify admins via websocket of new pending order
        (0, socket_1.emitNewOrderAdmin)(resultOrder);
        return {
            order: resultOrder,
        };
    }
    /**
     * Simulates/processes payment for an order.
     * If payment succeeds: status=PAID, updates stock, generates queue number, triggers WebSocket notification.
     */
    async processPayment(userId, orderId, paymentMethod) {
        const order = await database_1.default.order.findUnique({
            where: { id: orderId },
            include: {
                orderItems: {
                    include: {
                        product: true,
                        variant: true,
                    },
                },
            },
        });
        if (!order || order.userId !== userId) {
            throw new error_middleware_1.AppError(404, 'ORDER_NOT_FOUND', 'Order not found');
        }
        if (order.status !== 'PENDING') {
            throw new error_middleware_1.AppError(400, 'ORDER_ALREADY_PROCESSED', `Cannot pay for order with status: ${order.status}`);
        }
        // Begin payment checkout transaction
        const result = await database_1.default.$transaction(async (tx) => {
            // 1. Double check and decrement stock
            for (const item of order.orderItems) {
                if (item.variantId) {
                    const variant = await tx.productVariant.findUnique({ where: { id: item.variantId } });
                    if (!variant || variant.stock < item.quantity) {
                        throw new error_middleware_1.AppError(400, 'INSUFFICIENT_STOCK', `Variant ${item.variantName} is out of stock`);
                    }
                    await tx.productVariant.update({
                        where: { id: item.variantId },
                        data: { stock: variant.stock - item.quantity },
                    });
                    const parent = await tx.product.findUnique({ where: { id: item.productId } });
                    if (parent) {
                        await tx.product.update({
                            where: { id: item.productId },
                            data: { stock: Math.max(0, parent.stock - item.quantity) },
                        });
                    }
                }
                else {
                    const product = await tx.product.findUnique({ where: { id: item.productId } });
                    if (!product || product.stock < item.quantity) {
                        throw new error_middleware_1.AppError(400, 'INSUFFICIENT_STOCK', `Product ${item.productName} is out of stock`);
                    }
                    await tx.product.update({
                        where: { id: item.productId },
                        data: { stock: product.stock - item.quantity },
                    });
                }
            }
            // 2. Set order status as PAID (or PREPARING since normal flow proceeds immediately to preparation)
            // The prompt says: "Update paymentStatus=PAID, status=PAID"
            const updatedOrder = await tx.order.update({
                where: { id: orderId },
                data: {
                    status: order.isPreorder ? 'IN_PRODUCTION' : 'PAID',
                    paymentStatus: 'PAID',
                    paymentMethod,
                    paidAt: new Date(),
                },
            });
            // 3. Clear these items from the student's cart
            const productVariantCombinations = order.orderItems.map((item) => ({
                productId: item.productId,
                variantId: item.variantId,
            }));
            for (const comb of productVariantCombinations) {
                await tx.cartItem.deleteMany({
                    where: {
                        userId,
                        productId: comb.productId,
                        variantId: comb.variantId,
                    },
                });
            }
            // 4. Ensure queue number exists (reserved at QRIS checkout or generated now)
            const existingQueue = await tx.queue.findUnique({
                where: { orderId: order.id },
            });
            const startOfToday = new Date();
            startOfToday.setHours(0, 0, 0, 0);
            const endOfToday = new Date();
            endOfToday.setHours(23, 59, 59, 999);
            const pendingQueuesCount = await tx.queue.count({
                where: {
                    status: { in: ['WAITING', 'PREPARING'] },
                    queueDate: { gte: startOfToday, lte: endOfToday },
                },
            });
            const estimatedWaitMinutes = (pendingQueuesCount + 1) * 5;
            let queue;
            if (existingQueue) {
                queue = await tx.queue.update({
                    where: { id: existingQueue.id },
                    data: { estimatedWaitMinutes },
                });
            }
            else {
                const queueNumber = await (0, queue_number_1.generateNextQueueNumber)(tx);
                queue = await tx.queue.create({
                    data: {
                        orderId: order.id,
                        userId,
                        queueNumber,
                        queueDate: new Date(),
                        status: 'WAITING',
                        estimatedWaitMinutes,
                    },
                });
            }
            // 5. Create notification row
            const notification = await tx.notification.create({
                data: {
                    userId,
                    title: 'Pembayaran Berhasil',
                    body: `Pesanan ${order.orderNumber} telah dibayar. Nomor antrean Anda adalah ${queue.queueNumber}.`,
                    type: 'ORDER_STATUS',
                    referenceId: order.id,
                },
            });
            return {
                order: updatedOrder,
                queue,
                notification,
            };
        });
        // Broadcast queue update to real-time socket
        (0, socket_1.emitQueueUpdate)(userId, {
            queueId: result.queue.id,
            orderId: result.order.id,
            orderNumber: order.orderNumber,
            status: result.queue.status,
            queueNumber: result.queue.queueNumber,
            estimatedWait: result.queue.estimatedWaitMinutes,
            event: 'PAYMENT_SUCCESS',
        });
        (0, socket_1.emitOrderStatusUpdate)(userId, {
            orderId: result.order.id,
            orderNumber: order.orderNumber,
            status: result.order.status,
            statusLabel: 'Dibayar',
            queueId: result.queue.id,
            queueNumber: result.queue.queueNumber,
            title: 'Pembayaran Berhasil',
            body: `Pesanan ${order.orderNumber} telah dibayar. Nomor antrean Anda adalah ${result.queue.queueNumber}.`,
        });
        (0, socket_1.emitUserNotification)(userId, {
            id: result.notification.id,
            title: result.notification.title,
            body: result.notification.body,
            type: result.notification.type,
            referenceId: result.notification.referenceId,
        });
        return result;
    }
    /**
     * Fetches orders list for a student (paginated).
     */
    async getStudentOrders(userId, filters) {
        const { status, isPreorder, page, limit } = filters;
        const where = { userId };
        if (status) {
            where.status = status;
        }
        if (isPreorder !== undefined) {
            where.isPreorder = isPreorder;
        }
        const offset = (page - 1) * limit;
        const [orders, totalItems] = await Promise.all([
            database_1.default.order.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip: offset,
                take: limit,
                include: {
                    orderItems: {
                        include: {
                            product: {
                                select: {
                                    imageUrl: true,
                                    category: { select: { name: true } },
                                },
                            },
                        },
                    },
                    queue: true,
                },
            }),
            database_1.default.order.count({ where }),
        ]);
        const pagination = (0, pagination_1.getPaginationMetadata)(page, limit, totalItems);
        return {
            orders,
            pagination,
        };
    }
    /**
     * Fetches order details.
     */
    async getOrderDetails(userId, orderId) {
        const order = await database_1.default.order.findUnique({
            where: { id: orderId },
            include: {
                orderItems: {
                    include: {
                        product: {
                            select: {
                                imageUrl: true,
                                category: { select: { name: true } },
                            },
                        },
                    },
                },
                queue: true,
                user: {
                    select: {
                        id: true,
                        fullName: true,
                        email: true,
                        phone: true,
                    },
                },
            },
        });
        if (!order || (order.userId !== userId && order.user.id !== userId)) {
            // Ensure users can only query their own orders (unless admin, but this service supports public user checks)
            throw new error_middleware_1.AppError(404, 'ORDER_NOT_FOUND', 'Order not found');
        }
        return order;
    }
    /**
     * Cancels a pending order.
     */
    async cancelOrder(userId, orderId) {
        const order = await database_1.default.order.findUnique({
            where: { id: orderId },
        });
        if (!order || order.userId !== userId) {
            throw new error_middleware_1.AppError(404, 'ORDER_NOT_FOUND', 'Order not found');
        }
        if (order.status !== 'PENDING') {
            throw new error_middleware_1.AppError(400, 'ORDER_CANNOT_BE_CANCELLED', `Cannot cancel order with status: ${order.status}`);
        }
        const updated = await database_1.default.$transaction(async (tx) => {
            await tx.queue.deleteMany({
                where: { orderId },
            });
            return tx.order.update({
                where: { id: orderId },
                data: {
                    status: 'CANCELLED',
                },
            });
        });
        return updated;
    }
    /**
     * Admin: Fetches paginated orders list with search, status, and date range filters.
     */
    async getAllOrdersAdmin(filters) {
        const { status, search, dateFrom, dateTo, page, limit } = filters;
        const offset = (page - 1) * limit;
        const where = {};
        if (status) {
            where.status = status;
        }
        if (search) {
            where.OR = [
                { orderNumber: { contains: search, mode: 'insensitive' } },
                { user: { fullName: { contains: search, mode: 'insensitive' } } },
            ];
        }
        if (dateFrom || dateTo) {
            where.createdAt = {};
            if (dateFrom) {
                where.createdAt.gte = new Date(dateFrom);
            }
            if (dateTo) {
                const to = new Date(dateTo);
                to.setHours(23, 59, 59, 999);
                where.createdAt.lte = to;
            }
        }
        const [orders, totalItems] = await Promise.all([
            database_1.default.order.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip: offset,
                take: limit,
                include: {
                    user: {
                        select: {
                            fullName: true,
                            email: true,
                        },
                    },
                    orderItems: true,
                },
            }),
            database_1.default.order.count({ where }),
        ]);
        const totalPages = Math.ceil(totalItems / limit) || 1;
        const pagination = { page, limit, totalItems, totalPages };
        return {
            orders,
            pagination,
        };
    }
    /**
     * Admin: View details of any customer order.
     */
    async getOrderDetailsAdmin(orderId) {
        const order = await database_1.default.order.findUnique({
            where: { id: orderId },
            include: {
                orderItems: true,
                queue: true,
                user: {
                    select: {
                        id: true,
                        fullName: true,
                        email: true,
                        phone: true,
                    },
                },
            },
        });
        if (!order) {
            throw new error_middleware_1.AppError(404, 'ORDER_NOT_FOUND', 'Order not found');
        }
        return order;
    }
    /**
     * Admin: Updates order status manually.
     * When an order that already consumed stock (paid/preparing/etc.) is cancelled,
     * its stock is returned so inventory stays consistent.
     */
    async updateOrderStatusAdmin(orderId, status) {
        const order = await database_1.default.order.findUnique({
            where: { id: orderId },
            include: {
                orderItems: {
                    include: { product: true },
                },
            },
        });
        if (!order) {
            throw new error_middleware_1.AppError(404, 'ORDER_NOT_FOUND', 'Order not found');
        }
        // Stock was decremented at payment time. So any status other than PENDING /
        // CANCELLED means stock is currently being held by this order.
        const stockWasConsumed = order.status !== 'PENDING' && order.status !== 'CANCELLED';
        const shouldRestoreStock = status === 'CANCELLED' && stockWasConsumed;
        const updated = await database_1.default.$transaction(async (tx) => {
            if (shouldRestoreStock) {
                for (const item of order.orderItems) {
                    // Preorder items never decremented stock, so skip them.
                    if (item.product.isPreorder)
                        continue;
                    if (item.variantId) {
                        await tx.productVariant.update({
                            where: { id: item.variantId },
                            data: { stock: { increment: item.quantity } },
                        });
                    }
                    // The parent product stock is decremented for both variant and
                    // non-variant sales, so always return it here.
                    await tx.product.update({
                        where: { id: item.productId },
                        data: { stock: { increment: item.quantity } },
                    });
                }
            }
            return tx.order.update({
                where: { id: orderId },
                data: { status },
                select: {
                    id: true,
                    userId: true,
                    orderNumber: true,
                    status: true,
                },
            });
        });
        const statusLabel = orderStatusLabel(status);
        const title = 'Status Pesanan Diperbarui';
        const body = `Status pesanan ${updated.orderNumber} diubah menjadi ${statusLabel}.`;
        // Create notification entry for order status change
        const notification = await database_1.default.notification.create({
            data: {
                userId: updated.userId,
                title,
                body,
                type: 'ORDER_STATUS',
                referenceId: updated.id,
            },
        });
        const queue = await database_1.default.queue.findUnique({
            where: { orderId: updated.id },
            select: { id: true },
        });
        (0, socket_1.emitOrderStatusUpdate)(updated.userId, {
            orderId: updated.id,
            orderNumber: updated.orderNumber,
            status: updated.status,
            statusLabel,
            title,
            body,
            queueId: queue?.id ?? null,
            isPreorder: order.isPreorder,
        });
        (0, socket_1.emitUserNotification)(updated.userId, {
            id: notification.id,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            referenceId: notification.referenceId,
        });
        return updated;
    }
}
exports.OrdersService = OrdersService;
function orderStatusLabel(status) {
    switch (status) {
        case 'PENDING':
            return 'Menunggu Pembayaran';
        case 'PAID':
            return 'Dibayar';
        case 'PREPARING':
            return 'Sedang Disiapkan';
        case 'IN_PRODUCTION':
            return 'Dalam Produksi';
        case 'READY':
            return 'Siap Diambil';
        case 'COMPLETED':
            return 'Selesai';
        case 'CANCELLED':
            return 'Dibatalkan';
        default:
            return status;
    }
}
exports.default = OrdersService;
