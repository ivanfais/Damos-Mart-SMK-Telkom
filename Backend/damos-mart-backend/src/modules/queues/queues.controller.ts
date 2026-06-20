import { Request, Response, NextFunction } from 'express';
import { QueuesService } from './queues.service';

const queuesService = new QueuesService();

export class QueuesController {
  /**
   * Fetches logged-in student's active queues.
   */
  async getActiveQueues(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const queues = await queuesService.getActiveQueues(userId);
      return res.status(200).json({
        success: true,
        data: queues,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Fetches single queue details and QR scanning representation string.
   */
  async getQueueDetails(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { id } = req.params;

      const data = await queuesService.getQueueById(userId, id);
      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Fetches current serving status and waiting count for dashboard indicators.
   */
  async getCurrentState(req: Request, res: Response, next: NextFunction) {
    try {
      const state = await queuesService.getCurrentQueueState();
      return res.status(200).json({
        success: true,
        data: state,
      });
    } catch (error) {
      return next(error);
    }
  }

  // ==========================================
  // ADMIN HANDLERS
  // ==========================================

  /**
   * Admin: Get all queues created today.
   */
  async getAdminQueues(req: Request, res: Response, next: NextFunction) {
    try {
      const queues = await queuesService.getAllTodayQueues();
      return res.status(200).json({
        success: true,
        data: queues,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Process queue (WAITING -> PREPARING)
   */
  async callQueue(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const queue = await queuesService.callQueue(id);
      return res.status(200).json({
        success: true,
        data: queue,
        message: 'Queue called successfully. Status set to PREPARING.',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Mark prepared (PREPARING -> READY)
   */
  async readyQueue(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const queue = await queuesService.readyQueue(id);
      return res.status(200).json({
        success: true,
        data: queue,
        message: 'Queue set to READY. Student notified.',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Confirm pickup (READY -> COMPLETED)
   */
  async completeQueue(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const queue = await queuesService.completeQueue(id);
      return res.status(200).json({
        success: true,
        data: queue,
        message: 'Order pickup confirmed. Queue completed.',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Skip queue
   */
  async skipQueue(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const queue = await queuesService.skipQueue(id);
      return res.status(200).json({
        success: true,
        data: queue,
        message: 'Queue skipped.',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: QR scan to complete queue.
   */
  async scanQR(req: Request, res: Response, next: NextFunction) {
    try {
      const { qrData } = req.body;
      const queue = await queuesService.scanQR(qrData);
      return res.status(200).json({
        success: true,
        data: queue,
        message: 'QR scan successful. Queue completed.',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default QueuesController;
