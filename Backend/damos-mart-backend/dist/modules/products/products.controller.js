"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProductsController = void 0;
const products_service_1 = require("./products.service");
const productsService = new products_service_1.ProductsService();
class ProductsController {
    /**
     * Fetches paginated, filtered active products list (Public/Student).
     */
    async getAll(req, res, next) {
        try {
            const { category, search, inStock, isPreorder, sort, page, limit } = req.query;
            const filters = {
                category,
                search,
                inStock: inStock === 'true' ? true : inStock === 'false' ? false : undefined,
                isPreorder: isPreorder === 'true' ? true : isPreorder === 'false' ? false : undefined,
                sort,
                page: parseInt(page) || 1,
                limit: parseInt(limit) || 20,
                isAdminView: false,
            };
            const result = await productsService.getAll(filters);
            return res.status(200).json({
                success: true,
                data: result.products,
                pagination: result.pagination,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches featured products list (Public/Student).
     */
    async getFeatured(req, res, next) {
        try {
            const limit = parseInt(req.query.limit) || 10;
            const products = await productsService.getFeatured(limit);
            return res.status(200).json({
                success: true,
                data: products,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches full product details.
     */
    async getById(req, res, next) {
        try {
            const { id } = req.params;
            const product = await productsService.getById(id);
            return res.status(200).json({
                success: true,
                data: product,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches paginated product reviews.
     */
    async getProductReviews(req, res, next) {
        try {
            const { id } = req.params;
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 10;
            const result = await productsService.getProductReviews(id, page, limit);
            return res.status(200).json({
                success: true,
                data: result.reviews,
                pagination: result.pagination,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    // ==========================================
    // ADMIN HANDLERS
    // ==========================================
    /**
     * Fetches paginated, filtered products (Admin View, includes inactive products).
     */
    async getAdminProducts(req, res, next) {
        try {
            const { category, search, page, limit } = req.query;
            const filters = {
                category,
                search,
                page: parseInt(page) || 1,
                limit: parseInt(limit) || 20,
                isAdminView: true,
            };
            const result = await productsService.getAll(filters);
            return res.status(200).json({
                success: true,
                data: result.products,
                pagination: result.pagination,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Creates a new product.
     */
    async create(req, res, next) {
        try {
            let imageUrl;
            if (req.file) {
                imageUrl = `/uploads/products/${req.file.filename}`;
            }
            const product = await productsService.create(req.body, imageUrl);
            return res.status(201).json({
                success: true,
                data: product,
                message: 'Product created successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Updates an existing product.
     */
    async update(req, res, next) {
        try {
            const { id } = req.params;
            let imageUrl;
            if (req.file) {
                imageUrl = `/uploads/products/${req.file.filename}`;
            }
            const product = await productsService.update(id, req.body, imageUrl);
            return res.status(200).json({
                success: true,
                data: product,
                message: 'Product updated successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Deletes a product.
     */
    async delete(req, res, next) {
        try {
            const { id } = req.params;
            await productsService.delete(id);
            return res.status(200).json({
                success: true,
                message: 'Product deleted successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Adds variant to a product.
     */
    async createVariant(req, res, next) {
        try {
            const { id } = req.params;
            let imageUrl;
            if (req.file) {
                imageUrl = `/uploads/products/${req.file.filename}`;
            }
            const variant = await productsService.createVariant(id, req.body, imageUrl);
            return res.status(201).json({
                success: true,
                data: variant,
                message: 'Product variant created successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Updates a product variant.
     */
    async updateVariant(req, res, next) {
        try {
            const { id, vid } = req.params;
            let imageUrl;
            if (req.file) {
                imageUrl = `/uploads/products/${req.file.filename}`;
            }
            const variant = await productsService.updateVariant(id, vid, req.body, imageUrl);
            return res.status(200).json({
                success: true,
                data: variant,
                message: 'Product variant updated successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Deletes a product variant.
     */
    async deleteVariant(req, res, next) {
        try {
            const { id, vid } = req.params;
            await productsService.deleteVariant(id, vid);
            return res.status(200).json({
                success: true,
                message: 'Product variant deleted successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.ProductsController = ProductsController;
exports.default = ProductsController;
