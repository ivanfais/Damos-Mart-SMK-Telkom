"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminChatRouter = void 0;
const express_1 = require("express");
const chat_controller_1 = require("./chat.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const router = (0, express_1.Router)();
const controller = new chat_controller_1.ChatController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// All chat routes require user authentication
router.use(auth_middleware_1.authMiddleware);
router.get('/room', bind('getRoom'));
router.get('/room/:id/messages', bind('getRoomMessages'));
router.post('/room/:id/messages', bind('sendMessage'));
// Admin Chat routes
exports.adminChatRouter = (0, express_1.Router)();
exports.adminChatRouter.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
exports.adminChatRouter.get('/rooms', bind('getAdminRooms'));
exports.adminChatRouter.get('/rooms/:id/messages', bind('getRoomMessages'));
exports.adminChatRouter.post('/rooms/:id/messages', bind('sendMessage'));
exports.default = router;
