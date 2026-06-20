"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createReviewSchema = void 0;
const zod_1 = require("zod");
exports.createReviewSchema = zod_1.z.object({
    body: zod_1.z.object({
        productId: zod_1.z.string().uuid('Invalid product ID'),
        orderId: zod_1.z.string().uuid('Invalid order ID'),
        rating: zod_1.z.coerce.number().int().min(1, 'Rating must be at least 1').max(5, 'Rating cannot exceed 5'),
        comment: zod_1.z.string().optional().nullable(),
    }),
});
