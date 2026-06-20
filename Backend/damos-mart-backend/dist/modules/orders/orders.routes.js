"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const orders_controller_1 = require("./orders.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const validate_middleware_1 = require("../../middlewares/validate.middleware");
const orders_schema_1 = require("./orders.schema");
const router = (0, express_1.Router)();
const controller = new orders_controller_1.OrdersController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// All order operations require student authentication
router.use(auth_middleware_1.authMiddleware);
router.post('/', (0, validate_middleware_1.validateRequest)(orders_schema_1.createOrderSchema), bind('createOrder'));
router.get('/', bind('getMyOrders'));
router.get('/:id', bind('getOrderDetails'));
router.post('/:id/pay', (0, validate_middleware_1.validateRequest)(orders_schema_1.processPaymentSchema), bind('payOrder'));
router.post('/:id/cancel', bind('cancelOrder'));
exports.default = router;
