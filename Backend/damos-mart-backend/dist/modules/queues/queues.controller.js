"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.QueuesController = void 0;
const queues_service_1 = require("./queues.service");
const queuesService = new queues_service_1.QueuesService();
class QueuesController {
    /**
     * Fetches logged-in student's active queues.
     */
    async getActiveQueues(req, res, next) {
        try {
            const userId = req.user.userId;
            const queues = await queuesService.getActiveQueues(userId);
            return res.status(200).json({
                success: true,
                data: queues,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches single queue details and QR scanning representation string.
     */
    async getQueueDetails(req, res, next) {
        try {
            const userId = req.user.userId;
            const { id } = req.params;
            const data = await queuesService.getQueueById(userId, id);
            return res.status(200).json({
                success: true,
                data,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Fetches current serving status and waiting count for dashboard indicators.
     */
    async getCurrentState(req, res, next) {
        try {
            const state = await queuesService.getCurrentQueueState();
            return res.status(200).json({
                success: true,
                data: state,
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
     * Admin: Get all queues created today.
     */
    async getAdminQueues(req, res, next) {
        try {
            const queues = await queuesService.getAllTodayQueues();
            return res.status(200).json({
                success: true,
                data: queues,
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Process queue (WAITING -> PREPARING)
     */
    async callQueue(req, res, next) {
        try {
            const { id } = req.params;
            const queue = await queuesService.callQueue(id);
            return res.status(200).json({
                success: true,
                data: queue,
                message: 'Queue called successfully. Status set to PREPARING.',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Mark prepared (PREPARING -> READY)
     */
    async readyQueue(req, res, next) {
        try {
            const { id } = req.params;
            const queue = await queuesService.readyQueue(id);
            return res.status(200).json({
                success: true,
                data: queue,
                message: 'Queue set to READY. Student notified.',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Confirm pickup (READY -> COMPLETED)
     */
    async completeQueue(req, res, next) {
        try {
            const { id } = req.params;
            const queue = await queuesService.completeQueue(id);
            return res.status(200).json({
                success: true,
                data: queue,
                message: 'Order pickup confirmed. Queue completed.',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: Skip queue
     */
    async skipQueue(req, res, next) {
        try {
            const { id } = req.params;
            const queue = await queuesService.skipQueue(id);
            return res.status(200).json({
                success: true,
                data: queue,
                message: 'Queue skipped.',
            });
        }
        catch (error) {
            return next(error);
        }
    }
    /**
     * Admin: QR scan to complete queue.
     */
    async scanQR(req, res, next) {
        try {
            const { qrData } = req.body;
            const queue = await queuesService.scanQR(qrData);
            return res.status(200).json({
                success: true,
                data: queue,
                message: 'QR scan successful. Queue completed.',
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.QueuesController = QueuesController;
exports.default = QueuesController;
