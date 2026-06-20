import { Router, RequestHandler } from 'express';
import { QueuesController } from './queues.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';

const router = Router();
const controller = new QueuesController();

const bind = (method: keyof QueuesController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// All student routes require auth
router.use(authMiddleware);

router.get('/active', bind('getActiveQueues'));
router.get('/current', bind('getCurrentState'));
router.get('/:id', bind('getQueueDetails'));

// Admin Queue Management
export const adminQueueRouter = Router();
adminQueueRouter.use(authMiddleware, adminMiddleware);

adminQueueRouter.get('/', bind('getAdminQueues'));
adminQueueRouter.put('/:id/call', bind('callQueue'));
adminQueueRouter.put('/:id/ready', bind('readyQueue'));
adminQueueRouter.put('/:id/complete', bind('completeQueue'));
adminQueueRouter.put('/:id/skip', bind('skipQueue'));
adminQueueRouter.post('/scan', bind('scanQR'));

export default router;
