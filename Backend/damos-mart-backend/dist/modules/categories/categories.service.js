"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CategoriesService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
class CategoriesService {
    /**
     * Fetches all categories sorted by sortOrder.
     */
    async getAll() {
        return database_1.default.category.findMany({
            orderBy: {
                sortOrder: 'asc',
            },
        });
    }
    /**
     * Fetches a category by ID.
     */
    async getById(id) {
        const category = await database_1.default.category.findUnique({
            where: { id },
        });
        if (!category) {
            throw new error_middleware_1.AppError(404, 'CATEGORY_NOT_FOUND', 'Category not found');
        }
        return category;
    }
    /**
     * Creates a new category (Admin).
     */
    async create(data, iconUrl) {
        return database_1.default.category.create({
            data: {
                name: data.name,
                sortOrder: data.sortOrder || 0,
                iconUrl,
            },
        });
    }
    /**
     * Updates an existing category (Admin).
     */
    async update(id, data, iconUrl) {
        await this.getById(id); // Ensure exists
        return database_1.default.category.update({
            where: { id },
            data: {
                ...data,
                ...(iconUrl && { iconUrl }),
            },
        });
    }
    /**
     * Deletes a category (Admin).
     */
    async delete(id) {
        await this.getById(id); // Ensure exists
        // Verify if there are any products attached to this category
        const productCount = await database_1.default.product.count({
            where: { categoryId: id },
        });
        if (productCount > 0) {
            throw new error_middleware_1.AppError(400, 'CATEGORY_IN_USE', 'Cannot delete category because it contains active products. Reassign or delete those products first.');
        }
        await database_1.default.category.delete({
            where: { id },
        });
    }
}
exports.CategoriesService = CategoriesService;
exports.default = CategoriesService;
