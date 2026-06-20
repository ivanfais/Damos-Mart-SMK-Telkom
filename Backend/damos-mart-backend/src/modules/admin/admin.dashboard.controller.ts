import { Request, Response, NextFunction } from 'express';
import { AdminDashboardService } from './admin.dashboard.service';

const dashboardService = new AdminDashboardService();

export class AdminDashboardController {
  /**
   * HTTP handler to fetch dashboard aggregate stats.
   */
  async getDashboardData(req: Request, res: Response, next: NextFunction) {
    try {
      const summary = await dashboardService.getDashboardSummary();
      return res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default AdminDashboardController;
