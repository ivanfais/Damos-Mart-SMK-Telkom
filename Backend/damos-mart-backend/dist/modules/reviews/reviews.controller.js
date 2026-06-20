"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReviewsController = void 0;
const reviews_service_1 = require("./reviews.service");
const reviewsService = new reviews_service_1.ReviewsService();
class ReviewsController {
    /**
     * HTTP handler to submit a new product review with optional photos.
     */
    async submitReview(req, res, next) {
        try {
            const userId = req.user.userId;
            const files = req.files;
            const photoUrls = files ? files.map((file) => `/uploads/reviews/${file.filename}`) : [];
            const review = await reviewsService.submitReview(userId, req.body, photoUrls);
            return res.status(201).json({
                success: true,
                data: review,
                message: 'Review submitted successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.ReviewsController = ReviewsController;
exports.default = ReviewsController;
