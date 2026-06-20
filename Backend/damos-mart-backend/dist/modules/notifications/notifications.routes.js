"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const notifications_controller_1 = require("./notifications.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const router = (0, express_1.Router)();
const controller = new notifications_controller_1.NotificationsController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// All notification routes require student authentication
router.use(auth_middleware_1.authMiddleware);
router.get('/', bind('getNotifications'));
router.put('/:id/read', bind('readNotification'));
router.put('/read-all', bind('readAllNotifications'));
exports.default = router;
