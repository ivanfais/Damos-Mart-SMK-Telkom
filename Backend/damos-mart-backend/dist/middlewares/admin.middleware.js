"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminMiddleware = adminMiddleware;
const error_middleware_1 = require("./error.middleware");
/**
 * Middleware restricting access to ADMIN role only.
 * Requires authMiddleware to be registered before.
 */
function adminMiddleware(req, _res, next) {
    if (!req.user) {
        return next(new error_middleware_1.AppError(401, 'UNAUTHORIZED', 'Authentication is required'));
    }
    if (req.user.role !== 'ADMIN') {
        return next(new error_middleware_1.AppError(403, 'FORBIDDEN', 'Access denied. Admin role required'));
    }
    return next();
}
exports.default = adminMiddleware;
