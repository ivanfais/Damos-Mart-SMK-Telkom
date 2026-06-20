"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminCooperativeRouter = void 0;
const express_1 = require("express");
const cooperative_controller_1 = require("./cooperative.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const upload_middleware_1 = require("../../middlewares/upload.middleware");
const router = (0, express_1.Router)();
const controller = new cooperative_controller_1.CooperativeController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// Public Cooperative info routes
router.get('/info', bind('getInfo'));
router.get('/hours', bind('getHours'));
router.get('/crowd', bind('getCrowd'));
// Admin CRUD routes
exports.adminCooperativeRouter = (0, express_1.Router)();
exports.adminCooperativeRouter.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
exports.adminCooperativeRouter.post('/info', upload_middleware_1.uploadCooperative.single('image'), bind('createInfo'));
exports.adminCooperativeRouter.put('/info/:id', upload_middleware_1.uploadCooperative.single('image'), bind('updateInfo'));
exports.adminCooperativeRouter.delete('/info/:id', bind('deleteInfo'));
exports.adminCooperativeRouter.put('/hours', bind('updateHours'));
exports.default = router;
