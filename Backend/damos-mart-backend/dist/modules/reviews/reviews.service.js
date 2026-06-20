"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReviewsService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
class ReviewsService {
    /**
     * Submits a new product review and recalculates average ratings.
     */
    async submitReview(userId, data, photoUrls = []) {
        // 1. Verify that order exists, is COMPLETED, and contains this product
        const order = await database_1.default.order.findFirst({
            where: {
                id: data.orderId,
                userId,
                status: 'COMPLETED',
                orderItems: {
                    some: {
                        productId: data.productId,
                    },
                },
            },
        });
        if (!order) {
            throw new error_middleware_1.AppError(400, 'INVALID_REVIEW', 'Cannot review. Ensure the order is completed and contains this product.');
        }
        // 2. Check if user already reviewed this product in this order
        const existingReview = await database_1.default.review.findUnique({
            where: {
                userId_orderId_productId: {
                    userId,
                    orderId: data.orderId,
                    productId: data.productId,
                },
            },
        });
        if (existingReview) {
            throw new error_middleware_1.AppError(409, 'ALREADY_REVIEWED', 'You have already submitted a review for this product in this order');
        }
        // 3. Create review & recalculate rating in transaction
        const reviewResult = await database_1.default.$transaction(async (tx) => {
            // Create Review
            const review = await tx.review.create({
                data: {
                    userId,
                    productId: data.productId,
                    orderId: data.orderId,
                    rating: data.rating,
                    comment: data.comment,
                },
            });
            // Create Review Photos
            if (photoUrls.length > 0) {
                await tx.reviewPhoto.createMany({
                    data: photoUrls.map((url) => ({
                        reviewId: review.id,
                        photoUrl: url,
                    })),
                });
            }
            // Query aggregate rating stats for this product
            const stats = await tx.review.aggregate({
                where: { productId: data.productId },
                _avg: { rating: true },
                _count: { rating: true },
            });
            const averageRating = stats._avg.rating || 0;
            const totalReviews = stats._count.rating || 0;
            // Update Product record
            await tx.product.update({
                where: { id: data.productId },
                data: {
                    averageRating,
                    totalReviews,
                },
            });
            return tx.review.findUnique({
                where: { id: review.id },
                include: { photos: true },
            });
        });
        return reviewResult;
    }
}
exports.ReviewsService = ReviewsService;
exports.default = ReviewsService;
