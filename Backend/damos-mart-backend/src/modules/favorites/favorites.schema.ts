import { z } from 'zod';

export const addFavoriteSchema = z.object({
  productId: z.string().uuid('ID produk tidak valid'),
});

export const listFavoritesSchema = z.object({
  category: z.string().uuid().optional(),
  search: z.string().trim().optional(),
});
