import { Router } from 'express';
import { OrdersService } from '../orders/orders.service';
import { AdminDashboardController } from './admin.dashboard.controller';
import { AdminReportsController } from './admin.reports.controller';

// Subrouters imports
import { adminProductRouter } from '../products/products.routes';
import { adminCategoryRouter } from '../categories/categories.routes';
import { adminQueueRouter } from '../queues/queues.routes';
import { adminChatRouter } from '../chat/chat.routes';
import { adminUserRouter } from '../users/users.routes';
import { adminCooperativeRouter } from '../cooperative/cooperative.routes';
import { adminComplaintRouter } from '../complaints/complaints.routes';

// Guard Middlewares
import { authMiddleware } from '../../middlewares/auth.middleware';
import { adminMiddleware } from '../../middlewares/admin.middleware';

const router = Router();
const ordersService = new OrdersService();
const dashboardController = new AdminDashboardController();
const reportsController = new AdminReportsController();

// Protect ALL routes mounted in the admin subrouter
router.use(authMiddleware, adminMiddleware);

// Dashboard statistics
router.get('/dashboard', (req, res, next) => dashboardController.getDashboardData(req, res, next));

// Charts & Sales Reports
router.get('/reports/sales', (req, res, next) => reportsController.getSalesReport(req, res, next));

// Admin Order Handlers
router.get('/orders', async (req, res, next) => {
  try {
    const { status, search, dateFrom, dateTo, page, limit } = req.query as any;
    const result = await ordersService.getAllOrdersAdmin({
      status,
      search,
      dateFrom,
      dateTo,
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });
    return res.status(200).json({
      success: true,
      data: result.orders,
      pagination: result.pagination,
    });
  } catch (error) {
    return next(error);
  }
});

router.get('/orders/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const order = await ordersService.getOrderDetailsAdmin(id);
    return res.status(200).json({
      success: true,
      data: order,
    });
  } catch (error) {
    return next(error);
  }
});

router.put('/orders/:id/status', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const order = await ordersService.updateOrderStatusAdmin(id, status);
    return res.status(200).json({
      success: true,
      data: order,
      message: 'Order status updated successfully',
    });
  } catch (error) {
    return next(error);
  }
});

// Nest module routers
router.use('/products', adminProductRouter);
router.use('/categories', adminCategoryRouter);
router.use('/queues', adminQueueRouter);
router.use('/chat', adminChatRouter);
router.use('/users', adminUserRouter);
router.use('/cooperative', adminCooperativeRouter);
router.use('/complaints', adminComplaintRouter);

export default router;
