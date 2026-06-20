import { Router, RequestHandler } from 'express';
import { NotificationsController } from './notifications.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';

const router = Router();
const controller = new NotificationsController();

const bind = (method: keyof NotificationsController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// All notification routes require student authentication
router.use(authMiddleware);

router.get('/', bind('getNotifications'));
router.put('/:id/read', bind('readNotification'));
router.put('/read-all', bind('readAllNotifications'));

export default router;
