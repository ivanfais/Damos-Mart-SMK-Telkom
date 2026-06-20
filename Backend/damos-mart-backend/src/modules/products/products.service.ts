import { Prisma } from '@prisma/client';
import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';
import { getPaginationMetadata } from '../../utils/pagination';
import {
  CreateProductInput,
  UpdateProductInput,
  CreateVariantInput,
  UpdateVariantInput,
} from './products.schema';

export class ProductsService {
  /**
   * Fetch paginated and filtered list of active products (Student View).
   */
  async getAll(filters: {
    category?: string;
    search?: string;
    inStock?: boolean;
    isPreorder?: boolean;
    sort?: 'newest' | 'price_asc' | 'price_desc' | 'rating_desc' | 'popular';
    page: number;
    limit: number;
    isAdminView?: boolean;
  }) {
    const { category, search, inStock, isPreorder, sort, page, limit, isAdminView } = filters;

    // Build Prisma query filters
    const where: Prisma.ProductWhereInput = {};

    // For public view, only show active products
    if (!isAdminView) {
      where.isActive = true;
    }

    if (category) {
      where.categoryId = category;
    }

    if (search) {
      where.name = {
        contains: search,
        mode: 'insensitive',
      };
    }

    if (inStock === true) {
      where.stock = { gt: 0 };
    } else if (inStock === false) {
      where.stock = 0;
    }

    if (isPreorder !== undefined) {
      where.isPreorder = isPreorder;
    }

    // Build Prisma ordering
    let orderBy: Prisma.ProductOrderByWithRelationInput = { createdAt: 'desc' };
    if (sort === 'price_asc') {
      orderBy = { price: 'asc' };
    } else if (sort === 'price_desc') {
      orderBy = { price: 'desc' };
    } else if (sort === 'rating_desc') {
      orderBy = { averageRating: 'desc' };
    } else if (sort === 'popular') {
      orderBy = { totalReviews: 'desc' };
    } else if (sort === 'newest') {
      orderBy = { createdAt: 'desc' };
    }

    const offset = (page - 1) * limit;

    const [products, totalItems] = await Promise.all([
      prisma.product.findMany({
        where,
        orderBy,
        skip: offset,
        take: limit,
        include: {
          category: {
            select: {
              name: true,
            },
          },
          variants: true,
        },
      }),
      prisma.product.count({ where }),
    ]);

    const pagination = getPaginationMetadata(page, limit, totalItems);

    return {
      products,
      pagination,
    };
  }

  /**
   * Fetches featured products.
   */
  async getFeatured(limit: number) {
    return prisma.product.findMany({
      where: {
        isActive: true,
      },
      orderBy: [
        { averageRating: 'desc' },
        { totalReviews: 'desc' },
      ],
      take: limit,
      include: {
        category: {
          select: { name: true },
        },
        variants: true,
      },
    });
  }

  /**
   * Fetches product details including variants and recent reviews.
   */
  async getById(id: string) {
    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        category: {
          select: { name: true },
        },
        variants: {
          orderBy: { createdAt: 'asc' },
        },
        reviews: {
          take: 5,
          orderBy: { createdAt: 'desc' },
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                avatarUrl: true,
              },
            },
            photos: true,
          },
        },
      },
    });

    if (!product) {
      throw new AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found');
    }

    return product;
  }

  /**
   * Fetches paginated reviews for a specific product.
   */
  async getProductReviews(productId: string, page: number, limit: number) {
    const offset = (page - 1) * limit;

    const [reviews, totalItems] = await Promise.all([
      prisma.review.findMany({
        where: { productId },
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              fullName: true,
              avatarUrl: true,
            },
          },
          photos: true,
        },
      }),
      prisma.review.count({ where: { productId } }),
    ]);

    const pagination = getPaginationMetadata(page, limit, totalItems);

    return {
      reviews,
      pagination,
    };
  }

  /**
   * Creates a new product (Admin).
   */
  async create(data: CreateProductInput, imageUrl?: string) {
    return prisma.product.create({
      data: {
        categoryId: data.categoryId,
        name: data.name,
        description: data.description,
        price: data.price,
        stock: data.stock,
        isPreorder: data.isPreorder,
        preorderEstimation: data.preorderEstimation,
        imageUrl,
      },
    });
  }

  /**
   * Updates an existing product (Admin).
   */
  async update(id: string, data: UpdateProductInput, imageUrl?: string) {
    await this.getById(id); // Check existence

    const updateData: any = { ...data };
    if (imageUrl) {
      updateData.imageUrl = imageUrl;
    }

    const product = await prisma.product.update({
      where: { id },
      data: updateData,
      include: {
        variants: true,
      },
    });

    // If the product has variants, its main stock is derived from them.
    if (product.variants.length > 0) {
      await this.syncProductStockFromVariants(id);
      return prisma.product.findUnique({ where: { id }, include: { variants: true } });
    }

    return product;
  }

  /**
   * Deletes a product (Admin).
   */
  async delete(id: string) {
    await this.getById(id); // Check existence

    await prisma.product.delete({
      where: { id },
    });
  }

  /**
   * Recomputes a product's main stock from the sum of its variant stocks.
   * When a product has variants, the main stock is derived (no longer managed
   * manually). If no variants remain, the manual main stock is left untouched.
   */
  private async syncProductStockFromVariants(productId: string) {
    const variants = await prisma.productVariant.findMany({
      where: { productId },
      select: { stock: true },
    });

    if (variants.length === 0) return;

    const totalStock = variants.reduce((sum, v) => sum + v.stock, 0);
    await prisma.product.update({
      where: { id: productId },
      data: { stock: totalStock },
    });
  }

  /**
   * Adds a variant to a product (Admin).
   */
  async createVariant(productId: string, data: CreateVariantInput) {
    await this.getById(productId); // Check existence

    const variant = await prisma.productVariant.create({
      data: {
        productId,
        variantName: data.variantName,
        additionalPrice: data.additionalPrice,
        stock: data.stock,
      },
    });

    await this.syncProductStockFromVariants(productId);

    return variant;
  }

  /**
   * Updates a product variant (Admin).
   */
  async updateVariant(productId: string, variantId: string, data: UpdateVariantInput) {
    const variant = await prisma.productVariant.findFirst({
      where: { id: variantId, productId },
    });

    if (!variant) {
      throw new AppError(404, 'VARIANT_NOT_FOUND', 'Product variant not found');
    }

    const updated = await prisma.productVariant.update({
      where: { id: variantId },
      data,
    });

    await this.syncProductStockFromVariants(productId);

    return updated;
  }

  /**
   * Deletes a product variant (Admin).
   */
  async deleteVariant(productId: string, variantId: string) {
    const variant = await prisma.productVariant.findFirst({
      where: { id: variantId, productId },
    });

    if (!variant) {
      throw new AppError(404, 'VARIANT_NOT_FOUND', 'Product variant not found');
    }

    await prisma.productVariant.delete({
      where: { id: variantId },
    });

    await this.syncProductStockFromVariants(productId);
  }
}
export default ProductsService;
