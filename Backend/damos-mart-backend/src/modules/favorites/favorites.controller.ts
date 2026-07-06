import { Request, Response, NextFunction } from 'express';
import { FavoritesService } from './favorites.service';

const service = new FavoritesService();

export class FavoritesController {
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { category, search } = req.query as { category?: string; search?: string };
      const products = await service.getFavorites(userId, { category, search });
      return res.status(200).json({ success: true, data: products });
    } catch (error) {
      return next(error);
    }
  }

  async listIds(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const ids = await service.getFavoriteIds(userId);
      return res.status(200).json({ success: true, data: ids });
    } catch (error) {
      return next(error);
    }
  }

  async add(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { productId } = req.body;
      const result = await service.add(userId, productId);
      return res.status(201).json({
        success: true,
        data: result,
        message: 'Produk ditambahkan ke favorit',
      });
    } catch (error) {
      return next(error);
    }
  }

  async remove(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const result = await service.remove(userId, req.params.productId);
      return res.status(200).json({
        success: true,
        data: result,
        message: 'Produk dihapus dari favorit',
      });
    } catch (error) {
      return next(error);
    }
  }

  async toggle(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const result = await service.toggle(userId, req.params.productId);
      return res.status(200).json({
        success: true,
        data: result,
        message: result.isFavorite
          ? 'Produk ditambahkan ke favorit'
          : 'Produk dihapus dari favorit',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default FavoritesController;
