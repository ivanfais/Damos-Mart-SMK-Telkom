"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const auth_service_1 = require("./auth.service");
const authService = new auth_service_1.AuthService();
class AuthController {
    /**
     * HTTP Handler for Student Registration.
     */
    async register(req, res, next) {
        try {
            const data = await authService.register(req.body);
            return res.status(201).json({
                success: true,
                data,
                message: 'Registration successful',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP Handler for Email + Password Login.
     */
    async login(req, res, next) {
        try {
            const data = await authService.login(req.body);
            return res.status(200).json({
                success: true,
                data,
                message: 'Login successful',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP Handler for School SSO Login simulation.
     */
    async loginSso(req, res, next) {
        try {
            const data = await authService.loginSso(req.body);
            return res.status(200).json({
                success: true,
                data,
                message: 'SSO Login successful',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP Handler to Refresh Access and Refresh Tokens.
     */
    async refresh(req, res, next) {
        try {
            const { refreshToken } = req.body;
            const data = await authService.refresh(refreshToken);
            return res.status(200).json({
                success: true,
                data,
                message: 'Tokens refreshed successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP Handler to Log Out (invalidate refresh token).
     */
    async logout(req, res, next) {
        try {
            const { refreshToken } = req.body;
            await authService.logout(refreshToken);
            return res.status(200).json({
                success: true,
                message: 'Logout successful',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP Handler for forgot password (validate registered email).
     */
    async forgotPassword(req, res, next) {
        try {
            const data = await authService.requestPasswordReset(req.body);
            return res.status(200).json({
                success: true,
                data,
                message: data.message,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * HTTP Handler for reset password with verification code.
     */
    async resetPassword(req, res, next) {
        try {
            const data = await authService.resetPassword(req.body);
            return res.status(200).json({
                success: true,
                data,
                message: data.message,
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.AuthController = AuthController;
exports.default = AuthController;
