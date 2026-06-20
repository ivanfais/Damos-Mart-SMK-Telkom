import { Request, Response, NextFunction } from 'express';
import { ComplaintsService } from './complaints.service';

const service = new ComplaintsService();

export class ComplaintsController {
  // ---- Student handlers ----

  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user?.userId ?? null;
      const complaint = await service.create(userId, req.body);
      return res.status(201).json({
        success: true,
        data: complaint,
        message: 'Komplain berhasil dikirim',
      });
    } catch (error) {
      return next(error);
    }
  }

  async getMine(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const complaints = await service.getByUser(userId);
      return res.status(200).json({ success: true, data: complaints });
    } catch (error) {
      return next(error);
    }
  }

  // ---- Admin handlers ----

  async adminList(req: Request, res: Response, next: NextFunction) {
    try {
      const { status, category, priority, search, page, limit } = req.query as any;
      const result = await service.getAllAdmin({
        status,
        category,
        priority,
        search,
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 10,
      });
      return res.status(200).json({
        success: true,
        data: result.complaints,
        pagination: result.pagination,
      });
    } catch (error) {
      return next(error);
    }
  }

  async adminStats(_req: Request, res: Response, next: NextFunction) {
    try {
      const stats = await service.getStats();
      return res.status(200).json({ success: true, data: stats });
    } catch (error) {
      return next(error);
    }
  }

  async adminGetById(req: Request, res: Response, next: NextFunction) {
    try {
      const complaint = await service.getById(req.params.id);
      return res.status(200).json({ success: true, data: complaint });
    } catch (error) {
      return next(error);
    }
  }

  async adminCreate(req: Request, res: Response, next: NextFunction) {
    try {
      const { userId, ...rest } = req.body;
      const complaint = await service.create(userId ?? null, rest);
      return res.status(201).json({
        success: true,
        data: complaint,
        message: 'Komplain berhasil dicatat',
      });
    } catch (error) {
      return next(error);
    }
  }

  async adminUpdateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const complaint = await service.updateStatus(req.params.id, req.body);
      return res.status(200).json({
        success: true,
        data: complaint,
        message: 'Status komplain diperbarui',
      });
    } catch (error) {
      return next(error);
    }
  }

  async adminRespond(req: Request, res: Response, next: NextFunction) {
    try {
      const complaint = await service.respond(req.params.id, req.body);
      return res.status(200).json({
        success: true,
        data: complaint,
        message: 'Balasan komplain terkirim',
      });
    } catch (error) {
      return next(error);
    }
  }

  async adminDelete(req: Request, res: Response, next: NextFunction) {
    try {
      await service.remove(req.params.id);
      return res.status(200).json({ success: true, message: 'Komplain dihapus' });
    } catch (error) {
      return next(error);
    }
  }
}

export default ComplaintsController;
