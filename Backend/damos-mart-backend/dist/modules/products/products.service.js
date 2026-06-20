"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProductsService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
const pagination_1 = require("../../utils/pagination");
class ProductsService {
    /**
     * Fetch paginated and filtered list of active products (Student View).
     */
    async getAll(filters) {
        const { category, search, inStock, isPreorder, sort, page, limit, isAdminView } = filters;
        // Build Prisma query filters
        const where = {};
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
        }
        else if (inStock === false) {
            where.stock = 0;
        }
        if (isPreorder !== undefined) {
            where.isPreorder = isPreorder;
        }
        // Build Prisma ordering
        let orderBy = { createdAt: 'desc' };
        if (sort === 'price_asc') {
            orderBy = { price: 'asc' };
        }
        else if (sort === 'price_desc') {
            orderBy = { price: 'desc' };
        }
        else if (sort === 'rating_desc') {
            orderBy = { averageRating: 'desc' };
        }
        else if (sort === 'popular') {
            orderBy = { totalReviews: 'desc' };
        }
        else if (sort === 'newest') {
            orderBy = { createdAt: 'desc' };
        }
        const offset = (page - 1) * limit;
        const [products, totalItems] = await Promise.all([
            database_1.default.product.findMany({
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
            database_1.default.product.count({ where }),
        ]);
        const pagination = (0, pagination_1.getPaginationMetadata)(page, limit, totalItems);
        return {
            products,
            pagination,
        };
    }
    /**
     * Fetches featured products.
     */
    async getFeatured(limit) {
        return database_1.default.product.findMany({
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
    async getById(id) {
        const product = await database_1.default.product.findUnique({
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
            throw new error_middleware_1.AppError(404, 'PRODUCT_NOT_FOUND', 'Product not found');
        }
        return product;
    }
    /**
     * Fetches paginated reviews for a specific product.
     */
    async getProductReviews(productId, page, limit) {
        const offset = (page - 1) * limit;
        const [reviews, totalItems] = await Promise.all([
            database_1.default.review.findMany({
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
            database_1.default.review.count({ where: { productId } }),
        ]);
        const pagination = (0, pagination_1.getPaginationMetadata)(page, limit, totalItems);
        return {
            reviews,
            pagination,
        };
    }
    /**
     * Creates a new product (Admin).
     */
    async create(data, imageUrl) {
        return database_1.default.product.create({
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
    async update(id, data, imageUrl) {
        await this.getById(id); // Check existence
        const updateData = { ...data };
        if (imageUrl) {
            updateData.imageUrl = imageUrl;
        }
        return database_1.default.product.update({
            where: { id },
            data: updateData,
            include: {
                variants: true,
            },
        });
    }
    /**
     * Deletes a product (Admin).
     */
    async delete(id) {
        await this.getById(id); // Check existence
        await database_1.default.product.delete({
            where: { id },
        });
    }
    /**
     * Adds a variant to a product (Admin).
     */
    async createVariant(productId, data) {
        await this.getById(productId); // Check existence
        return database_1.default.productVariant.create({
            data: {
                productId,
                variantName: data.variantName,
                additionalPrice: data.additionalPrice,
                stock: data.stock,
            },
        });
    }
    /**
     * Updates a product variant (Admin).
     */
    async updateVariant(productId, variantId, data) {
        const variant = await database_1.default.productVariant.findFirst({
            where: { id: variantId, productId },
        });
        if (!variant) {
            throw new error_middleware_1.AppError(404, 'VARIANT_NOT_FOUND', 'Product variant not found');
        }
        return database_1.default.productVariant.update({
            where: { id: variantId },
            data,
        });
    }
    /**
     * Deletes a product variant (Admin).
     */
    async deleteVariant(productId, variantId) {
        const variant = await database_1.default.productVariant.findFirst({
            where: { id: variantId, productId },
        });
        if (!variant) {
            throw new error_middleware_1.AppError(404, 'VARIANT_NOT_FOUND', 'Product variant not found');
        }
        await database_1.default.productVariant.delete({
            where: { id: variantId },
        });
    }
}
exports.ProductsService = ProductsService;
exports.default = ProductsService;
