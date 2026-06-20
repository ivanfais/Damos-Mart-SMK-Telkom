"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const reviews_controller_1 = require("./reviews.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const upload_middleware_1 = require("../../middlewares/upload.middleware");
const validate_middleware_1 = require("../../middlewares/validate.middleware");
const reviews_schema_1 = require("./reviews.schema");
const router = (0, express_1.Router)();
const controller = new reviews_controller_1.ReviewsController();
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
// Reviews require student authentication
router.post('/', auth_middleware_1.authMiddleware, upload_middleware_1.uploadReview.array('photos', 5), (0, validate_middleware_1.validateRequest)(reviews_schema_1.createReviewSchema), bind('submitReview'));
exports.default = router;
