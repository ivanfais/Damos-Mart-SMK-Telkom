import { Request, Response, NextFunction } from 'express';
import { CooperativeService } from './cooperative.service';

const coopService = new CooperativeService();

export class CooperativeController {
  /**
   * Fetches active info.
   */
  async getInfo(req: Request, res: Response, next: NextFunction) {
    try {
      const items = await coopService.getActiveInfo();
      return res.status(200).json({
        success: true,
        data: items,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Fetches operating hours.
   */
  async getHours(req: Request, res: Response, next: NextFunction) {
    try {
      const hours = await coopService.getOperatingHours();
      return res.status(200).json({
        success: true,
        data: hours,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Fetches crowd levels statistics.
   */
  async getCrowd(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await coopService.getCrowdData();
      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Fetches real-time cooperative condition.
   */
  async getStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const status = await coopService.getCurrentStatus();
      return res.status(200).json({
        success: true,
        data: status,
      });
    } catch (error) {
      return next(error);
    }
  }

  // ==========================================
  // ADMIN HANDLERS
  // ==========================================

  /**
   * Admin: Creates cooperative information post.
   */
  async createInfo(req: Request, res: Response, next: NextFunction) {
    try {
      let imageUrl: string | undefined;
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
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Updates cooperative information post.
   */
  async updateInfo(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      let imageUrl: string | undefined;
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
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Deletes cooperative information post.
   */
  async deleteInfo(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      await coopService.deleteInfo(id);
      return res.status(200).json({
        success: true,
        message: 'Cooperative info deleted successfully',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Bulk updates operational hours per day.
   */
  async updateHours(req: Request, res: Response, next: NextFunction) {
    try {
      const { hours } = req.body; // Expects array in hours property
      const updated = await coopService.updateOperatingHours(hours);
      return res.status(200).json({
        success: true,
        data: updated,
        message: 'Operating hours updated successfully',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Bulk upserts crowd density data.
   */
  async updateCrowd(req: Request, res: Response, next: NextFunction) {
    try {
      const { slots } = req.body;
      const updated = await coopService.updateCrowdData(slots);
      return res.status(200).json({
        success: true,
        data: updated,
        message: 'Crowd density data updated successfully',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Admin: Updates real-time cooperative condition.
   */
  async updateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { condition } = req.body;
      const updated = await coopService.updateCurrentStatus(condition);
      return res.status(200).json({
        success: true,
        data: updated,
        message: 'Cooperative condition updated successfully',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default CooperativeController;
