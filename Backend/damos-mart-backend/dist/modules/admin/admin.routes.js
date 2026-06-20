"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const orders_service_1 = require("../orders/orders.service");
const admin_dashboard_controller_1 = require("./admin.dashboard.controller");
const admin_reports_controller_1 = require("./admin.reports.controller");
// Subrouters imports
const products_routes_1 = require("../products/products.routes");
const categories_routes_1 = require("../categories/categories.routes");
const queues_routes_1 = require("../queues/queues.routes");
const chat_routes_1 = require("../chat/chat.routes");
const users_routes_1 = require("../users/users.routes");
const cooperative_routes_1 = require("../cooperative/cooperative.routes");
// Guard Middlewares
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const router = (0, express_1.Router)();
const ordersService = new orders_service_1.OrdersService();
const dashboardController = new admin_dashboard_controller_1.AdminDashboardController();
const reportsController = new admin_reports_controller_1.AdminReportsController();
// Protect ALL routes mounted in the admin subrouter
router.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
// Dashboard statistics
router.get('/dashboard', (req, res, next) => dashboardController.getDashboardData(req, res, next));
// Charts & Sales Reports
router.get('/reports/sales', (req, res, next) => reportsController.getSalesReport(req, res, next));
// Admin Order Handlers
router.get('/orders', async (req, res, next) => {
    try {
        const { status, search, dateFrom, dateTo, page, limit } = req.query;
        const result = await ordersService.getAllOrdersAdmin({
            status,
            search,
            dateFrom,
            dateTo,
            page: parseInt(page) || 1,
            limit: parseInt(limit) || 20,
        });
        return res.status(200).json({
            success: true,
            data: result.orders,
            pagination: result.pagination,
        });
    }
    catch (error) {
        return next(error);
    }
});
router.get('/orders/:id', async (req, res, next) => {
    try {
        const { id } = req.params;
        const order = await ordersService.getOrderDetailsAdmin(id);
        return res.status(200).json({
            success: true,
            data: order,
        });
    }
    catch (error) {
        return next(error);
    }
});
router.put('/orders/:id/status', async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const order = await ordersService.updateOrderStatusAdmin(id, status);
        return res.status(200).json({
            success: true,
            data: order,
            message: 'Order status updated successfully',
        });
    }
    catch (error) {
        return next(error);
    }
});
// Nest module routers
router.use('/products', products_routes_1.adminProductRouter);
router.use('/categories', categories_routes_1.adminCategoryRouter);
router.use('/queues', queues_routes_1.adminQueueRouter);
router.use('/chat', chat_routes_1.adminChatRouter);
router.use('/users', users_routes_1.adminUserRouter);
router.use('/cooperative', cooperative_routes_1.adminCooperativeRouter);
exports.default = router;
