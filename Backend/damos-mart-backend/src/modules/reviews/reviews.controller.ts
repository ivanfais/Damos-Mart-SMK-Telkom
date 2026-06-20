import { Request, Response, NextFunction } from 'express';
import { ReviewsService } from './reviews.service';

const reviewsService = new ReviewsService();

export class ReviewsController {
  /**
   * HTTP handler to submit a new product review with optional photos.
   */
  async submitReview(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      
      const files = req.files as Express.Multer.File[];
      const photoUrls = files ? files.map((file) => `/uploads/reviews/${file.filename}`) : [];

      const review = await reviewsService.submitReview(userId, req.body, photoUrls);

      return res.status(201).json({
        success: true,
        data: review,
        message: 'Review submitted successfully',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default ReviewsController;
