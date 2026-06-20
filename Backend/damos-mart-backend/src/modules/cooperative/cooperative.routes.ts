import { Router, RequestHandler } from 'express';
import { CooperativeController } from './cooperative.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';
import { uploadCooperative } from '../../middlewares/upload.middleware';

const router = Router();
const controller = new CooperativeController();

const bind = (method: keyof CooperativeController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// Public Cooperative info routes
router.get('/info', bind('getInfo'));
router.get('/hours', bind('getHours'));
router.get('/crowd', bind('getCrowd'));
router.get('/status', bind('getStatus'));

// Admin CRUD routes
export const adminCooperativeRouter = Router();
adminCooperativeRouter.use(authMiddleware, adminMiddleware);

adminCooperativeRouter.post('/info', uploadCooperative.single('image'), bind('createInfo'));
adminCooperativeRouter.put('/info/:id', uploadCooperative.single('image'), bind('updateInfo'));
adminCooperativeRouter.delete('/info/:id', bind('deleteInfo'));
adminCooperativeRouter.put('/hours', bind('updateHours'));
adminCooperativeRouter.put('/crowd', bind('updateCrowd'));
adminCooperativeRouter.put('/status', bind('updateStatus'));

export default router;
