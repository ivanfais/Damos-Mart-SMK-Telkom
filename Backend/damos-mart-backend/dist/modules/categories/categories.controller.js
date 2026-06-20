"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CategoriesController = void 0;
const categories_service_1 = require("./categories.service");
const categoriesService = new categories_service_1.CategoriesService();
class CategoriesController {
    /**
     * Fetches all categories (Public / Student view).
     */
    async getAll(req, res, next) {
        try {
            const categories = await categoriesService.getAll();
            return res.status(200).json({
                success: true,
                data: categories,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches category by ID.
     */
    async getById(req, res, next) {
        try {
            const { id } = req.params;
            const category = await categoriesService.getById(id);
            return res.status(200).json({
                success: true,
                data: category,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Creates new category (Admin).
     */
    async create(req, res, next) {
        try {
            let iconUrl;
            if (req.file) {
                // Save relative path for easy static serving
                iconUrl = `/uploads/categories/${req.file.filename}`;
            }
            const category = await categoriesService.create(req.body, iconUrl);
            return res.status(201).json({
                success: true,
                data: category,
                message: 'Category created successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Updates category (Admin).
     */
    async update(req, res, next) {
        try {
            const { id } = req.params;
            let iconUrl;
            if (req.file) {
                iconUrl = `/uploads/categories/${req.file.filename}`;
            }
            const category = await categoriesService.update(id, req.body, iconUrl);
            return res.status(200).json({
                success: true,
                data: category,
                message: 'Category updated successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Deletes category (Admin).
     */
    async delete(req, res, next) {
        try {
            const { id } = req.params;
            await categoriesService.delete(id);
            return res.status(200).json({
                success: true,
                message: 'Category deleted successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.CategoriesController = CategoriesController;
exports.default = CategoriesController;
