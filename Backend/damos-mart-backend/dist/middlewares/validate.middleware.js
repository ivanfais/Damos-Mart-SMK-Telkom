"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateRequest = void 0;
/**
 * Request validation middleware using Zod schema.
 * Supports validation of body, query, and params.
 */
const validateRequest = (schema) => {
    return async (req, res, next) => {
        try {
            const parsed = await schema.parseAsync({
                body: req.body,
                query: req.query,
                params: req.params,
            });
            // Replace with validated, typed values
            req.body = parsed.body;
            req.query = parsed.query;
            req.params = parsed.params;
            return next();
        }
        catch (error) {
            return next(error);
        }
    };
};
exports.validateRequest = validateRequest;
exports.default = exports.validateRequest;
