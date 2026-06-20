import { Router, RequestHandler } from 'express';
import { ChatController } from './chat.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';

const router = Router();
const controller = new ChatController();

const bind = (method: keyof ChatController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// All chat routes require user authentication
router.use(authMiddleware);

router.get('/room', bind('getRoom'));
router.get('/room/:id/messages', bind('getRoomMessages'));
router.post('/room/:id/messages', bind('sendMessage'));

// Admin Chat routes
export const adminChatRouter = Router();
adminChatRouter.use(authMiddleware, adminMiddleware);

adminChatRouter.get('/rooms', bind('getAdminRooms'));
adminChatRouter.get('/rooms/:id/messages', bind('getRoomMessages'));
adminChatRouter.post('/rooms/:id/messages', bind('sendMessage'));

export default router;
