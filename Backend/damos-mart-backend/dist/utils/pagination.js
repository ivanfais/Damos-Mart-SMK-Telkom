"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPaginationMetadata = getPaginationMetadata;
/**
 * Calculates pagination metadata for response matching API response format.
 */
function getPaginationMetadata(page, limit, totalItems) {
    const totalPages = Math.ceil(totalItems / limit) || 1;
    return {
        page,
        limit,
        totalItems,
        totalPages,
    };
}
