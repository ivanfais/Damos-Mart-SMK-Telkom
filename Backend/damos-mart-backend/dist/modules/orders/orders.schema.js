"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processPaymentSchema = exports.createOrderSchema = void 0;
const zod_1 = require("zod");
exports.createOrderSchema = zod_1.z.object({
    body: zod_1.z.object({
        cartItemIds: zod_1.z.array(zod_1.z.string().uuid('Invalid cart item ID')).min(1, 'At least one cart item is required to create an order'),
        paymentMethod: zod_1.z.enum(['QRIS', 'CASH_AT_COUNTER'], {
            required_error: 'Payment method is required',
        }),
        notes: zod_1.z.string().optional().nullable(),
    }),
});
exports.processPaymentSchema = zod_1.z.object({
    body: zod_1.z.object({
        paymentMethod: zod_1.z.enum(['QRIS', 'CASH_AT_COUNTER'], {
            required_error: 'Payment method is required',
        }),
    }),
});
