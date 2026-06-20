import { Request, Response, NextFunction } from 'express';
import { AdminReportsService } from './admin.reports.service';

const reportsService = new AdminReportsService();

export class AdminReportsController {
  /**
   * HTTP handler to generate sales report charts.
   */
  async getSalesReport(req: Request, res: Response, next: NextFunction) {
    try {
      const period = (req.query.period as 'daily' | 'weekly' | 'monthly') || 'daily';
      
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
    } catch (error) {
      return next(error);
    }
  }
}

export default AdminReportsController;
