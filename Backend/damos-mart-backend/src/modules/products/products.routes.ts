import { Router, RequestHandler } from 'express';
import { ProductsController } from './products.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';
import { uploadProduct } from '../../middlewares/upload.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import {
  productQuerySchema,
  createProductSchema,
  updateProductSchema,
  createVariantSchema,
  updateVariantSchema,
} from './products.schema';

const router = Router();
const controller = new ProductsController();

const bind = (method: keyof ProductsController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// Public Routes
router.get('/', validateRequest(productQuerySchema), bind('getAll'));
router.get('/featured', bind('getFeatured'));
router.get('/:id', bind('getById'));
router.get('/:id/reviews', bind('getProductReviews'));

// Admin CRUD Routes
export const adminProductRouter = Router();
adminProductRouter.use(authMiddleware, adminMiddleware);

adminProductRouter.get('/', bind('getAdminProducts'));
adminProductRouter.post('/', uploadProduct.single('image'), validateRequest(createProductSchema), bind('create'));
adminProductRouter.put('/:id', uploadProduct.single('image'), validateRequest(updateProductSchema), bind('update'));
adminProductRouter.delete('/:id', bind('delete'));

// Product Variants routes
adminProductRouter.post('/:id/variants', uploadProduct.single('image'), validateRequest(createVariantSchema), bind('createVariant'));
adminProductRouter.put('/:id/variants/:vid', uploadProduct.single('image'), validateRequest(updateVariantSchema), bind('updateVariant'));
adminProductRouter.delete('/:id/variants/:vid', bind('deleteVariant'));

export default router;
