import { z } from 'zod';

export const productQuerySchema = z.object({
  query: z.object({
    category: z.string().optional(),
    search: z.string().optional(),
    inStock: z.enum(['true', 'false']).optional().default('true'),
    isPreorder: z.enum(['true', 'false']).optional(),
    sort: z.enum(['newest', 'price_asc', 'price_desc', 'rating_desc', 'popular']).optional().default('newest'),
    page: z.coerce.number().int().min(1).optional().default(1),
    limit: z.coerce.number().int().min(1).optional().default(20),
  }),
});

export const createProductSchema = z.object({
  body: z.object({
    categoryId: z.string().uuid('Invalid category ID'),
    name: z.string().min(2, 'Product name must be at least 2 characters long'),
    description: z.string().optional().nullable(),
    price: z.coerce.number().positive('Price must be greater than 0'),
    stock: z.coerce.number().int().nonnegative('Stock cannot be negative').default(0),
    isPreorder: z.preprocess((val) => val === 'true' || val === true, z.boolean()).optional().default(false),
    preorderEstimation: z.string().optional().nullable(),
  }),
});

export const updateProductSchema = z.object({
  body: z.object({
    categoryId: z.string().uuid('Invalid category ID').optional(),
    name: z.string().min(2, 'Product name must be at least 2 characters long').optional(),
    description: z.string().optional().nullable(),
    price: z.coerce.number().positive('Price must be greater than 0').optional(),
    stock: z.coerce.number().int().nonnegative('Stock cannot be negative').optional(),
    isPreorder: z.preprocess((val) => val === 'true' || val === true, z.boolean()).optional(),
    preorderEstimation: z.string().optional().nullable(),
    isActive: z.preprocess((val) => val === 'true' || val === true, z.boolean()).optional(),
  }),
});

export const createVariantSchema = z.object({
  body: z.object({
    variantName: z.string().min(1, 'Variant name is required'),
    additionalPrice: z.coerce.number().nonnegative('Additional price cannot be negative').default(0),
    stock: z.coerce.number().int().nonnegative('Variant stock cannot be negative').default(0),
  }),
});

export const updateVariantSchema = z.object({
  body: z.object({
    variantName: z.string().min(1, 'Variant name is required').optional(),
    additionalPrice: z.coerce.number().nonnegative('Additional price cannot be negative').optional(),
    stock: z.coerce.number().int().nonnegative('Variant stock cannot be negative').optional(),
  }),
});

export type CreateProductInput = z.infer<typeof createProductSchema>['body'];
export type UpdateProductInput = z.infer<typeof updateProductSchema>['body'];
export type CreateVariantInput = z.infer<typeof createVariantSchema>['body'];
export type UpdateVariantInput = z.infer<typeof updateVariantSchema>['body'];
