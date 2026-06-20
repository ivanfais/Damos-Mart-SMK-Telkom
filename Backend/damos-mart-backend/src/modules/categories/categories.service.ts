import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';

export class CategoriesService {
  /**
   * Fetches all categories sorted by sortOrder.
   */
  async getAll() {
    return prisma.category.findMany({
      orderBy: {
        sortOrder: 'asc',
      },
    });
  }

  /**
   * Fetches a category by ID.
   */
  async getById(id: string) {
    const category = await prisma.category.findUnique({
      where: { id },
    });
    if (!category) {
      throw new AppError(404, 'CATEGORY_NOT_FOUND', 'Category not found');
    }
    return category;
  }

  /**
   * Creates a new category (Admin).
   */
  async create(data: { name: string; sortOrder?: number }, iconUrl?: string) {
    return prisma.category.create({
      data: {
        name: data.name,
        sortOrder: data.sortOrder || 0,
        iconUrl,
      },
    });
  }

  /**
   * Updates an existing category (Admin).
   */
  async update(id: string, data: { name?: string; sortOrder?: number }, iconUrl?: string) {
    await this.getById(id); // Ensure exists

    return prisma.category.update({
      where: { id },
      data: {
        ...data,
        ...(iconUrl && { iconUrl }),
      },
    });
  }

  /**
   * Deletes a category (Admin).
   */
  async delete(id: string) {
    await this.getById(id); // Ensure exists

    // Verify if there are any products attached to this category
    const productCount = await prisma.product.count({
      where: { categoryId: id },
    });

    if (productCount > 0) {
      throw new AppError(
        400,
        'CATEGORY_IN_USE',
        'Cannot delete category because it contains active products. Reassign or delete those products first.'
      );
    }

    await prisma.category.delete({
      where: { id },
    });
  }
}
export default CategoriesService;
