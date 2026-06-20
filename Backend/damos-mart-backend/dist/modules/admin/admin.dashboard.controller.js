"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminDashboardController = void 0;
const admin_dashboard_service_1 = require("./admin.dashboard.service");
const dashboardService = new admin_dashboard_service_1.AdminDashboardService();
class AdminDashboardController {
    /**
     * HTTP handler to fetch dashboard aggregate stats.
     */
    async getDashboardData(req, res, next) {
        try {
            const summary = await dashboardService.getDashboardSummary();
            return res.status(200).json({
                success: true,
                data: summary,
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.AdminDashboardController = AdminDashboardController;
exports.default = AdminDashboardController;
