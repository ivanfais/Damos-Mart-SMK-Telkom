import { Router, RequestHandler } from 'express';
import { ReviewsController } from './reviews.controller';
import { authMiddleware } from '../../middlewares/auth.middleware';
import { uploadReview } from '../../middlewares/upload.middleware';
import { validateRequest } from '../../middlewares/validate.middleware';
import { createReviewSchema } from './reviews.schema';

const router = Router();
const controller = new ReviewsController();

const bind = (method: keyof ReviewsController): RequestHandler => {
  return (req, res, next) => (controller[method] as any)(req, res, next);
};

// Reviews require student authentication
router.post(
  '/',
  authMiddleware,
  uploadReview.array('photos', 5),
  validateRequest(createReviewSchema),
  bind('submitReview')
);

export default router;
