"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersController = void 0;
const orders_service_1 = require("./orders.service");
const ordersService = new orders_service_1.OrdersService();
class OrdersController {
    /**
     * HTTP handler to create a new order from student's cart.
     */
    async createOrder(req, res, next) {
        try {
            const userId = req.user.userId;
            const { order } = await ordersService.createOrder(userId, req.body);
            return res.status(201).json({
                success: true,
                data: order,
                message: 'Order created successfully. Please complete the payment.',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP handler to pay for a pending order (creates daily Queue, reduces stock).
     */
    async payOrder(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            const { paymentMethod } = req.body;
            const result = await ordersService.processPayment(userId, id, paymentMethod);
            return res.status(200).json({
                success: true,
                data: result,
                message: 'Payment completed successfully. Queue number generated.',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP handler to fetch student's own order history.
     */
    async getMyOrders(req, res, next) {
        try {
            const userId = req.user.userId;
            const { status, isPreorder, page, limit } = req.query;
            const filters = {
                status,
                isPreorder: isPreorder === 'true' ? true : isPreorder === 'false' ? false : undefined,
                page: parseInt(page) || 1,
                limit: parseInt(limit) || 20,
            };
            const result = await ordersService.getStudentOrders(userId, filters);
            return res.status(200).json({
                success: true,
                data: result.orders,
                pagination: result.pagination,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP handler to view order details.
     */
    async getOrderDetails(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            const order = await ordersService.getOrderDetails(userId, id);
            return res.status(200).json({
                success: true,
                data: order,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP handler to cancel a pending order.
     */
    async cancelOrder(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            const order = await ordersService.cancelOrder(userId, id);
            return res.status(200).json({
                success: true,
                data: order,
                message: 'Order cancelled successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.OrdersController = OrdersController;
exports.default = OrdersController;
