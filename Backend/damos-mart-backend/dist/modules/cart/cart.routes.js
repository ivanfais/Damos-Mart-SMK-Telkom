"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const cart_controller_1 = require("./cart.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const validate_middleware_1 = require("../../middlewares/validate.middleware");
const cart_schema_1 = require("./cart.schema");
const router = (0, express_1.Router)();
const controller = new cart_controller_1.CartController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// All cart routes require student authentication
router.use(auth_middleware_1.authMiddleware);
router.get('/', bind('getCart'));
router.post('/', (0, validate_middleware_1.validateRequest)(cart_schema_1.addToCartSchema), bind('addToCart'));
router.put('/:id', (0, validate_middleware_1.validateRequest)(cart_schema_1.updateCartItemSchema), bind('updateQuantity'));
router.delete('/:id', bind('removeCartItem'));
router.delete('/', bind('clearCart'));
exports.default = router;
