import { z } from 'zod';

export const addToCartSchema = z.object({
  body: z.object({
    productId: z.string().uuid('Invalid product ID'),
    variantId: z.string().uuid('Invalid variant ID').optional().nullable(),
    quantity: z.coerce.number().int().positive('Quantity must be at least 1').default(1),
  }),
});

export const updateCartItemSchema = z.object({
  body: z.object({
    quantity: z.coerce.number().int().positive('Quantity must be at least 1'),
  }),
});
