"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("./auth.controller");
const validate_middleware_1 = require("../../middlewares/validate.middleware");
const auth_schema_1 = require("./auth.schema");
const router = (0, express_1.Router)();
const controller = new auth_controller_1.AuthController();
// Binding controller context helper
const bind = (method) => {
    return (req, res, next) => controller[method](req, res, next);
};
router.post('/register', (0, validate_middleware_1.validateRequest)(auth_schema_1.registerSchema), bind('register'));
router.post('/login', (0, validate_middleware_1.validateRequest)(auth_schema_1.loginSchema), bind('login'));
router.post('/login/sso', (0, validate_middleware_1.validateRequest)(auth_schema_1.ssoLoginSchema), bind('loginSso'));
router.post('/forgot-password', (0, validate_middleware_1.validateRequest)(auth_schema_1.forgotPasswordSchema), bind('forgotPassword'));
router.get('/reset-password/validate', (0, validate_middleware_1.validateRequest)(auth_schema_1.validateResetTokenSchema), bind('validateResetToken'));
router.post('/reset-password', (0, validate_middleware_1.validateRequest)(auth_schema_1.resetPasswordSchema), bind('resetPassword'));
router.post('/refresh', (0, validate_middleware_1.validateRequest)(auth_schema_1.refreshTokenSchema), bind('refresh'));
router.post('/logout', (0, validate_middleware_1.validateRequest)(auth_schema_1.refreshTokenSchema), bind('logout'));
exports.default = router;
