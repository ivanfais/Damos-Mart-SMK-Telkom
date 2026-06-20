"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminQueueRouter = void 0;
const express_1 = require("express");
const queues_controller_1 = require("./queues.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const router = (0, express_1.Router)();
const controller = new queues_controller_1.QueuesController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// All student routes require auth
router.use(auth_middleware_1.authMiddleware);
router.get('/active', bind('getActiveQueues'));
router.get('/current', bind('getCurrentState'));
router.get('/:id', bind('getQueueDetails'));
// Admin Queue Management
exports.adminQueueRouter = (0, express_1.Router)();
exports.adminQueueRouter.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
exports.adminQueueRouter.get('/', bind('getAdminQueues'));
exports.adminQueueRouter.put('/:id/call', bind('callQueue'));
exports.adminQueueRouter.put('/:id/ready', bind('readyQueue'));
exports.adminQueueRouter.put('/:id/complete', bind('completeQueue'));
exports.adminQueueRouter.put('/:id/skip', bind('skipQueue'));
exports.adminQueueRouter.post('/scan', bind('scanQR'));
exports.default = router;
