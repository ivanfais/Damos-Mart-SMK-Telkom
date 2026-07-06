import { Router, RequestHandler } from 'express';
import { ComplaintsController } from './complaints.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';
import { uploadComplaint } from '../../middlewares/upload.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import {
  createComplaintSchema,
  createReturnScheduleSchema,
  adminCreateComplaintSchema,
  updateComplaintStatusSchema,
  respondComplaintSchema,
} from './complaints.schema';

const controller = new ComplaintsController();

const bind = (method: keyof ComplaintsController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// ----- Student routes (Ajukan Komplain & Retur, wired on mobile) -----
const router = Router();
router.use(authMiddleware);
router.post(
  '/',
  uploadComplaint.array('photos', 3),
  validateRequest(createComplaintSchema),
  bind('submitComplaint')
);
router.get('/me', bind('getMine'));
router.get('/return-schedules/me', bind('getMyReturnSchedules'));
router.post(
  '/:id/return-schedule',
  validateRequest(createReturnScheduleSchema),
  bind('scheduleReturn')
);

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
