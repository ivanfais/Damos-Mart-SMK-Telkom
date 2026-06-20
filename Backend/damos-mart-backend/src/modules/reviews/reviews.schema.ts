import { z } from 'zod';

export const createReviewSchema = z.object({
  body: z.object({
    productId: z.string().uuid('Invalid product ID'),
    orderId: z.string().uuid('Invalid order ID'),
    rating: z.coerce.number().int().min(1, 'Rating must be at least 1').max(5, 'Rating cannot exceed 5'),
    comment: z.string().optional().nullable(),
  }),
});

export type CreateReviewInput = z.infer<typeof createReviewSchema>['body'];
