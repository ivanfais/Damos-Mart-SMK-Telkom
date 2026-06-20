import { Router, RequestHandler } from 'express';
import { CategoriesController } from './categories.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';
import { uploadCategory } from '../../middlewares/upload.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import { createCategorySchema, updateCategorySchema } from './categories.schema';

const router = Router();
const controller = new CategoriesController();

const bind = (method: keyof CategoriesController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// Public route
router.get('/', bind('getAll'));
router.get('/:id', bind('getById'));

// Admin CRUD routes (mapped inside category router or registered at admin prefix)
export const adminCategoryRouter = Router();
adminCategoryRouter.use(authMiddleware, adminMiddleware);

adminCategoryRouter.get('/', bind('getAll'));
adminCategoryRouter.post('/', uploadCategory.single('icon'), validateRequest(createCategorySchema), bind('create'));
adminCategoryRouter.put('/:id', uploadCategory.single('icon'), validateRequest(updateCategorySchema), bind('update'));
adminCategoryRouter.delete('/:id', bind('delete'));

export default router;
