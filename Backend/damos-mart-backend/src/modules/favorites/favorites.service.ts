import { Prisma } from '@prisma/client';
import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';

const productInclude = {
  category: {
    select: { name: true },
  },
  variants: true,
} as const;

export class FavoritesService {
  async getFavoriteIds(userId: string) {
    const rows = await prisma.productFavorite.findMany({
      where: { userId },
      select: { productId: true },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((row) => row.productId);
  }

  async getFavorites(
    userId: string,
    filters: { category?: string; search?: string }
  ) {
    const productWhere: Prisma.ProductWhereInput = {
      isActive: true,
    };

    if (filters.category) {
      productWhere.categoryId = filters.category;
    }

    if (filters.search) {
      productWhere.name = {
        contains: filters.search,
        mode: 'insensitive',
      };
    }

    const favorites = await prisma.productFavorite.findMany({
      where: {
        userId,
        product: productWhere,
      },
      orderBy: { createdAt: 'desc' },
      include: {
        product: {
          include: productInclude,
        },
      },
    });

    return favorites.map((item) => item.product);
  }

  async add(userId: string, productId: string) {
    const product = await prisma.product.findFirst({
      where: { id: productId, isActive: true },
    });

    if (!product) {
      throw new AppError(404, 'PRODUCT_NOT_FOUND', 'Produk tidak ditemukan');
    }

    const existing = await prisma.productFavorite.findUnique({
      where: {
        userId_productId: { userId, productId },
      },
    });

    if (existing) {
      return { productId, isFavorite: true };
    }

    await prisma.productFavorite.create({
      data: { userId, productId },
    });

    return { productId, isFavorite: true };
  }

  async remove(userId: string, productId: string) {
    const existing = await prisma.productFavorite.findUnique({
      where: {
        userId_productId: { userId, productId },
      },
    });

    if (!existing) {
      throw new AppError(404, 'FAVORITE_NOT_FOUND', 'Produk favorit tidak ditemukan');
    }

    await prisma.productFavorite.delete({
      where: { id: existing.id },
    });

    return { productId, isFavorite: false };
  }

  async toggle(userId: string, productId: string) {
    const existing = await prisma.productFavorite.findUnique({
      where: {
        userId_productId: { userId, productId },
      },
    });

    if (existing) {
      await prisma.productFavorite.delete({ where: { id: existing.id } });
      return { productId, isFavorite: false };
    }

    return this.add(userId, productId);
  }
}

export default FavoritesService;
