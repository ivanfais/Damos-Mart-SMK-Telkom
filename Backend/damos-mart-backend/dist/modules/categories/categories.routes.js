"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminCategoryRouter = void 0;
const express_1 = require("express");
const categories_controller_1 = require("./categories.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const upload_middleware_1 = require("../../middlewares/upload.middleware");
const validate_middleware_1 = require("../../middlewares/validate.middleware");
const categories_schema_1 = require("./categories.schema");
const router = (0, express_1.Router)();
const controller = new categories_controller_1.CategoriesController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// Public route
router.get('/', bind('getAll'));
router.get('/:id', bind('getById'));
// Admin CRUD routes (mapped inside category router or registered at admin prefix)
exports.adminCategoryRouter = (0, express_1.Router)();
exports.adminCategoryRouter.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
exports.adminCategoryRouter.get('/', bind('getAll'));
exports.adminCategoryRouter.post('/', upload_middleware_1.uploadCategory.single('icon'), (0, validate_middleware_1.validateRequest)(categories_schema_1.createCategorySchema), bind('create'));
exports.adminCategoryRouter.put('/:id', upload_middleware_1.uploadCategory.single('icon'), (0, validate_middleware_1.validateRequest)(categories_schema_1.updateCategorySchema), bind('update'));
exports.adminCategoryRouter.delete('/:id', bind('delete'));
exports.default = router;
