"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
const jwt_1 = require("../utils/jwt");
const error_middleware_1 = require("./error.middleware");
/**
 * Middleware enforcing authentication using Bearer JWT access tokens.
 * Injects decoded token payload as req.user
 */
function authMiddleware(req, _res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return next(new error_middleware_1.AppError(401, 'UNAUTHORIZED', 'Access token is missing or invalid'));
    }
    const token = authHeader.split(' ')[1];
    try {
        const decoded = (0, jwt_1.verifyAccessToken)(token);
        req.user = decoded;
        return next();
    }
    catch (error) {
        let msg = 'Invalid access token';
        if (error.name === 'TokenExpiredError') {
            msg = 'Access token has expired';
        }
        return next(new error_middleware_1.AppError(401, 'UNAUTHORIZED', msg));
    }
}
exports.default = authMiddleware;
