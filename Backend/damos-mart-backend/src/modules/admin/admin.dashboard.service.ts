import prisma from '../../config/database';

export class AdminDashboardService {
  /**
   * Fetches aggregate stats and recent orders for the admin dashboard.
   */
  async getDashboardSummary() {
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    // 1. Today's orders count
    const todayOrders = await prisma.order.count({
      where: {
        createdAt: {
          gte: startOfToday,
          lte: endOfToday,
        },
      },
    });

    // 2. Today's revenue (sum of totals of paid orders today)
    const todayRevenueSum = await prisma.order.aggregate({
      where: {
        paymentStatus: 'PAID',
        createdAt: {
          gte: startOfToday,
          lte: endOfToday,
        },
      },
      _sum: {
        total: true,
      },
    });
    const todayRevenue = Number(todayRevenueSum._sum.total || 0);

    // 3. Active queues (WAITING, PREPARING, READY today)
    const activeQueues = await prisma.queue.count({
      where: {
        status: { in: ['WAITING', 'PREPARING', 'READY'] },
        queueDate: new Date(),
      },
    });

    // 4. Low stock products count (products with stock < 10)
    const lowStockProducts = await prisma.product.count({
      where: {
        stock: { lt: 10 },
        isActive: true,
      },
    });

    // 5. Recent 10 orders
    const recentOrders = await prisma.order.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10,
      include: {
        user: {
          select: {
            fullName: true,
            email: true,
          },
        },
      },
    });

    return {
      todayOrders,
      todayRevenue,
      activeQueues,
      lowStockProducts,
      recentOrders,
    };
  }
}
export default AdminDashboardService;
