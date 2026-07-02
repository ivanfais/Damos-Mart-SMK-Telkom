import { Router, RequestHandler } from 'express';
import { FavoritesController } from './favorites.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import { addFavoriteSchema } from './favorites.schema';

const router = Router();
const controller = new FavoritesController();

const bind = (method: keyof FavoritesController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

router.use(authMiddleware);

router.get('/ids', bind('listIds'));
router.get('/', bind('list'));
router.post('/', validateRequest(addFavoriteSchema), bind('add'));
router.post('/:productId/toggle', bind('toggle'));
router.delete('/:productId', bind('remove'));

export default router;
