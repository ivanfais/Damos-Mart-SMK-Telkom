"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminProductRouter = void 0;
const express_1 = require("express");
const products_controller_1 = require("./products.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const upload_middleware_1 = require("../../middlewares/upload.middleware");
const validate_middleware_1 = require("../../middlewares/validate.middleware");
const products_schema_1 = require("./products.schema");
const router = (0, express_1.Router)();
const controller = new products_controller_1.ProductsController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// Public Routes
router.get('/', (0, validate_middleware_1.validateRequest)(products_schema_1.productQuerySchema), bind('getAll'));
router.get('/featured', bind('getFeatured'));
router.get('/:id', bind('getById'));
router.get('/:id/reviews', bind('getProductReviews'));
// Admin CRUD Routes
exports.adminProductRouter = (0, express_1.Router)();
exports.adminProductRouter.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
exports.adminProductRouter.get('/', bind('getAdminProducts'));
exports.adminProductRouter.post('/', upload_middleware_1.uploadProduct.single('image'), (0, validate_middleware_1.validateRequest)(products_schema_1.createProductSchema), bind('create'));
exports.adminProductRouter.put('/:id', upload_middleware_1.uploadProduct.single('image'), (0, validate_middleware_1.validateRequest)(products_schema_1.updateProductSchema), bind('update'));
exports.adminProductRouter.delete('/:id', bind('delete'));
// Product Variants routes
exports.adminProductRouter.post('/:id/variants', upload_middleware_1.uploadProduct.single('image'), (0, validate_middleware_1.validateRequest)(products_schema_1.createVariantSchema), bind('createVariant'));
exports.adminProductRouter.put('/:id/variants/:vid', upload_middleware_1.uploadProduct.single('image'), (0, validate_middleware_1.validateRequest)(products_schema_1.updateVariantSchema), bind('updateVariant'));
exports.adminProductRouter.delete('/:id/variants/:vid', bind('deleteVariant'));
exports.default = router;
