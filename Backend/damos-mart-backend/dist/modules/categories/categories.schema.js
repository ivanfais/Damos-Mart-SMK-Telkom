"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateCategorySchema = exports.createCategorySchema = void 0;
const zod_1 = require("zod");
exports.createCategorySchema = zod_1.z.object({
    body: zod_1.z.object({
        name: zod_1.z.string().min(2, 'Category name must be at least 2 characters long'),
        sortOrder: zod_1.z.coerce.number().optional().default(0),
    }),
});
exports.updateCategorySchema = zod_1.z.object({
    body: zod_1.z.object({
        name: zod_1.z.string().min(2, 'Category name must be at least 2 characters long').optional(),
        sortOrder: zod_1.z.coerce.number().optional(),
    }),
});
