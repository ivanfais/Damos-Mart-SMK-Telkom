import { Router, RequestHandler } from 'express';
import { CartController } from './cart.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import { addToCartSchema, updateCartItemSchema } from './cart.schema';

const router = Router();
const controller = new CartController();

const bind = (method: keyof CartController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// All cart routes require student authentication
router.use(authMiddleware);

router.get('/', bind('getCart'));
router.post('/', validateRequest(addToCartSchema), bind('addToCart'));
router.put('/:id', validateRequest(updateCartItemSchema), bind('updateQuantity'));
router.delete('/:id', bind('removeCartItem'));
router.delete('/', bind('clearCart'));

export default router;
