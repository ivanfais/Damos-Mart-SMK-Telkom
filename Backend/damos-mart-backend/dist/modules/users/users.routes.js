"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminUserRouter = void 0;
const express_1 = require("express");
const users_controller_1 = require("./users.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const upload_middleware_1 = require("../../middlewares/upload.middleware");
const router = (0, express_1.Router)();
const controller = new users_controller_1.UsersController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// Student profile endpoints
router.use(auth_middleware_1.authMiddleware);
router.get('/me', bind('getMe'));
router.put('/me', upload_middleware_1.uploadAvatar.single('avatar'), bind('updateMe'));
router.put('/me/password', bind('changePassword'));
// Admin User endpoints
exports.adminUserRouter = (0, express_1.Router)();
exports.adminUserRouter.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
exports.adminUserRouter.get('/', bind('getAdminUsers'));
exports.adminUserRouter.get('/:id', bind('getAdminUserDetails'));
exports.adminUserRouter.put('/:id/toggle-active', bind('toggleUserActive'));
exports.default = router;
