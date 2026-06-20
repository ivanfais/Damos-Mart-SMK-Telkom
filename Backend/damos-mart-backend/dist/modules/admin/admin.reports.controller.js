"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminReportsController = void 0;
const admin_reports_service_1 = require("./admin.reports.service");
const reportsService = new admin_reports_service_1.AdminReportsService();
class AdminReportsController {
    /**
     * HTTP handler to generate sales report charts.
     */
    async getSalesReport(req, res, next) {
        try {
            const period = req.query.period || 'daily';
            if (!['daily', 'weekly', 'monthly'].includes(period)) {
                return res.status(400).json({
                    success: false,
                    error: {
                        code: 'VALIDATION_ERROR',
                        message: "Period parameter must be 'daily', 'weekly', or 'monthly'",
                    },
                });
            }
            const report = await reportsService.getSalesReport(period);
            return res.status(200).json({
                success: true,
                data: report,
            });
        }
        catch (error) {
            return next(error);
        }
    }
}
exports.AdminReportsController = AdminReportsController;
exports.default = AdminReportsController;
