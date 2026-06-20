"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateVariantSchema = exports.createVariantSchema = exports.updateProductSchema = exports.createProductSchema = exports.productQuerySchema = void 0;
const zod_1 = require("zod");
exports.productQuerySchema = zod_1.z.object({
    query: zod_1.z.object({
        category: zod_1.z.string().optional(),
        search: zod_1.z.string().optional(),
        inStock: zod_1.z.enum(['true', 'false']).optional().default('true'),
        isPreorder: zod_1.z.enum(['true', 'false']).optional(),
        sort: zod_1.z.enum(['newest', 'price_asc', 'price_desc', 'rating_desc', 'popular']).optional().default('newest'),
        page: zod_1.z.coerce.number().int().min(1).optional().default(1),
        limit: zod_1.z.coerce.number().int().min(1).optional().default(20),
    }),
});
exports.createProductSchema = zod_1.z.object({
    body: zod_1.z.object({
        categoryId: zod_1.z.string().uuid('Invalid category ID'),
        name: zod_1.z.string().min(2, 'Product name must be at least 2 characters long'),
        description: zod_1.z.string().optional().nullable(),
        price: zod_1.z.coerce.number().positive('Price must be greater than 0'),
        stock: zod_1.z.coerce.number().int().nonnegative('Stock cannot be negative').default(0),
        isPreorder: zod_1.z.preprocess((val) => val === 'true' || val === true, zod_1.z.boolean()).optional().default(false),
        preorderEstimation: zod_1.z.string().optional().nullable(),
    }),
});
exports.updateProductSchema = zod_1.z.object({
    body: zod_1.z.object({
        categoryId: zod_1.z.string().uuid('Invalid category ID').optional(),
        name: zod_1.z.string().min(2, 'Product name must be at least 2 characters long').optional(),
        description: zod_1.z.string().optional().nullable(),
        price: zod_1.z.coerce.number().positive('Price must be greater than 0').optional(),
        stock: zod_1.z.coerce.number().int().nonnegative('Stock cannot be negative').optional(),
        isPreorder: zod_1.z.preprocess((val) => val === 'true' || val === true, zod_1.z.boolean()).optional(),
        preorderEstimation: zod_1.z.string().optional().nullable(),
        isActive: zod_1.z.preprocess((val) => val === 'true' || val === true, zod_1.z.boolean()).optional(),
    }),
});
exports.createVariantSchema = zod_1.z.object({
    body: zod_1.z.object({
        variantName: zod_1.z.string().min(1, 'Variant name is required'),
        additionalPrice: zod_1.z.coerce.number().nonnegative('Additional price cannot be negative').default(0),
        stock: zod_1.z.coerce.number().int().nonnegative('Variant stock cannot be negative').default(0),
    }),
});
exports.updateVariantSchema = zod_1.z.object({
    body: zod_1.z.object({
        variantName: zod_1.z.string().min(1, 'Variant name is required').optional(),
        additionalPrice: zod_1.z.coerce.number().nonnegative('Additional price cannot be negative').optional(),
        stock: zod_1.z.coerce.number().int().nonnegative('Variant stock cannot be negative').optional(),
    }),
});
