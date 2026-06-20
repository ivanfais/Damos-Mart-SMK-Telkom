import { Request, Response, NextFunction } from 'express';
import { CategoriesService } from './categories.service';

const categoriesService = new CategoriesService();

export class CategoriesController {
  /**
   * Fetches all categories (Public / Student view).
   */
  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const categories = await categoriesService.getAll();
      return res.status(200).json({
        success: true,
        data: categories,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Fetches category by ID.
   */
  async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const category = await categoriesService.getById(id);
      return res.status(200).json({
        success: true,
        data: category,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Creates new category (Admin).
   */
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      let iconUrl: string | undefined;
      if (req.file) {
        // Save relative path for easy static serving
        iconUrl = `/uploads/categories/${req.file.filename}`;
      }
      const category = await categoriesService.create(req.body, iconUrl);
      return res.status(201).json({
        success: true,
        data: category,
        message: 'Category created successfully',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Updates category (Admin).
   */
  async update(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      let iconUrl: string | undefined;
      if (req.file) {
        iconUrl = `/uploads/categories/${req.file.filename}`;
      }
      const category = await categoriesService.update(id, req.body, iconUrl);
      return res.status(200).json({
        success: true,
        data: category,
        message: 'Category updated successfully',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * Deletes category (Admin).
   */
  async delete(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      await categoriesService.delete(id);
      return res.status(200).json({
        success: true,
        message: 'Category deleted successfully',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default CategoriesController;
