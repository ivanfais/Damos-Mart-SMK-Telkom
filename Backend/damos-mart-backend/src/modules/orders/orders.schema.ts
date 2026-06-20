import { z } from 'zod';

export const createOrderSchema = z.object({
  body: z.object({
    cartItemIds: z.array(z.string().uuid('Invalid cart item ID')).min(1, 'At least one cart item is required to create an order'),
    paymentMethod: z.enum(['QRIS', 'CASH_AT_COUNTER'], {
      required_error: 'Payment method is required',
    }),
    notes: z.string().optional().nullable(),
  }),
});

export const processPaymentSchema = z.object({
  body: z.object({
    paymentMethod: z.enum(['QRIS', 'CASH_AT_COUNTER'], {
      required_error: 'Payment method is required',
    }),
  }),
});

export type CreateOrderInput = z.infer<typeof createOrderSchema>['body'];
export type ProcessPaymentInput = z.infer<typeof processPaymentSchema>['body'];
