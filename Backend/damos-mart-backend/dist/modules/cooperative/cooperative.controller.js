"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CooperativeController = void 0;
const cooperative_service_1 = require("./cooperative.service");
const coopService = new cooperative_service_1.CooperativeService();
class CooperativeController {
    /**
     * Fetches active info.
     */
    async getInfo(req, res, next) {
        try {
            const items = await coopService.getActiveInfo();
            return res.status(200).json({
                success: true,
                data: items,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches operating hours.
     */
    async getHours(req, res, next) {
        try {
            const hours = await coopService.getOperatingHours();
            return res.status(200).json({
                success: true,
                data: hours,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches crowd levels statistics.
     */
    async getCrowd(req, res, next) {
        try {
            const data = await coopService.getCrowdData();
            return res.status(200).json({
                success: true,
                data,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    // ==========================================
    // ADMIN HANDLERS
    // ==========================================
    /**
     * Admin: Creates cooperative information post.
     */
    async createInfo(req, res, next) {
        try {
            let imageUrl;
            if (req.file) {
                imageUrl = `/uploads/cooperative/${req.file.filename}`;
            }
            const info = await coopService.createInfo({
                ...req.body,
                imageUrl,
            });
            return res.status(201).json({
                success: true,
                data: info,
                message: 'Cooperative info created successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Updates cooperative information post.
     */
    async updateInfo(req, res, next) {
        try {
            const { id } = req.params;
            let imageUrl;
            if (req.file) {
                imageUrl = `/uploads/cooperative/${req.file.filename}`;
            }
            const info = await coopService.updateInfo(id, {
                ...req.body,
                ...(imageUrl && { imageUrl }),
            });
            return res.status(200).json({
                success: true,
                data: info,
                message: 'Cooperative info updated successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Deletes cooperative information post.
     */
    async deleteInfo(req, res, next) {
        try {
            const { id } = req.params;
            await coopService.deleteInfo(id);
            return res.status(200).json({
                success: true,
                message: 'Cooperative info deleted successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Bulk updates operational hours per day.
     */
    async updateHours(req, res, next) {
        try {
            const { hours } = req.body; // Expects array in hours property
            const updated = await coopService.updateOperatingHours(hours);
            return res.status(200).json({
                success: true,
                data: updated,
                message: 'Operating hours updated successfully',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.CooperativeController = CooperativeController;
exports.default = CooperativeController;
