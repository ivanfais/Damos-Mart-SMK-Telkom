import { Router, RequestHandler } from 'express';
import { OrdersController } from './orders.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import { createOrderSchema, processPaymentSchema } from './orders.schema';

const router = Router();
const controller = new OrdersController();

const bind = (method: keyof OrdersController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// All order operations require student authentication
router.use(authMiddleware);

router.post('/', validateRequest(createOrderSchema), bind('createOrder'));
router.get('/', bind('getMyOrders'));
router.get('/:id', bind('getOrderDetails'));
router.post('/:id/pay', validateRequest(processPaymentSchema), bind('payOrder'));
router.post('/:id/cancel', bind('cancelOrder'));

export default router;
