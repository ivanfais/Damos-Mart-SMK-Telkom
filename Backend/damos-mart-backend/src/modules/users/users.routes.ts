import { Router, RequestHandler } from 'express';
import { UsersController } from './users.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';
import { uploadAvatar } from '../../middlewares/upload.middleware';

const router = Router();
const controller = new UsersController();

const bind = (method: keyof UsersController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// Student profile endpoints
router.use(authMiddleware);

router.get('/me', bind('getMe'));
router.put('/me', uploadAvatar.single('avatar'), bind('updateMe'));
router.put('/me/password', bind('changePassword'));

// Admin User endpoints
export const adminUserRouter = Router();
adminUserRouter.use(authMiddleware, adminMiddleware);

adminUserRouter.get('/', bind('getAdminUsers'));
adminUserRouter.get('/:id', bind('getAdminUserDetails'));
adminUserRouter.put('/:id/toggle-active', bind('toggleUserActive'));

export default router;
