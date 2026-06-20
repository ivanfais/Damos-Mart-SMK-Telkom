import { Router, RequestHandler } from 'express';
import { ComplaintsController } from './complaints.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import {
  createComplaintSchema,
  adminCreateComplaintSchema,
  updateComplaintStatusSchema,
  respondComplaintSchema,
} from './complaints.schema';

const controller = new ComplaintsController();

const bind = (method: keyof ComplaintsController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// ----- Student routes (reserved for the Flutter app, not yet wired on mobile) -----
const router = Router();
router.use(authMiddleware);
router.post('/', validateRequest(createComplaintSchema), bind('create'));
router.get('/me', bind('getMine'));

// ----- Admin routes (mounted under /admin/complaints) -----
export const adminComplaintRouter = Router();
adminComplaintRouter.use(authMiddleware, adminMiddleware);

adminComplaintRouter.get('/', bind('adminList'));
adminComplaintRouter.get('/stats/summary', bind('adminStats'));
adminComplaintRouter.get('/:id', bind('adminGetById'));
adminComplaintRouter.post('/', validateRequest(adminCreateComplaintSchema), bind('adminCreate'));
adminComplaintRouter.put('/:id/status', validateRequest(updateComplaintStatusSchema), bind('adminUpdateStatus'));
adminComplaintRouter.put('/:id/respond', validateRequest(respondComplaintSchema), bind('adminRespond'));
adminComplaintRouter.delete('/:id', bind('adminDelete'));

export default router;
