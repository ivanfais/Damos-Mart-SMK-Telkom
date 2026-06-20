import { z } from 'zod';

export const createCategorySchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Category name must be at least 2 characters long'),
    sortOrder: z.coerce.number().optional().default(0),
  }),
});

export const updateCategorySchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Category name must be at least 2 characters long').optional(),
    sortOrder: z.coerce.number().optional(),
  }),
});
