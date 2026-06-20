"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateCartItemSchema = exports.addToCartSchema = void 0;
const zod_1 = require("zod");
exports.addToCartSchema = zod_1.z.object({
    body: zod_1.z.object({
        productId: zod_1.z.string().uuid('Invalid product ID'),
        variantId: zod_1.z.string().uuid('Invalid variant ID').optional().nullable(),
        quantity: zod_1.z.coerce.number().int().positive('Quantity must be at least 1').default(1),
    }),
});
exports.updateCartItemSchema = zod_1.z.object({
    body: zod_1.z.object({
        quantity: zod_1.z.coerce.number().int().positive('Quantity must be at least 1'),
    }),
});
