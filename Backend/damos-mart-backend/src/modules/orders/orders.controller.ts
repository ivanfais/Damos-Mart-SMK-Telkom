import { Request, Response, NextFunction } from 'express';
import { OrdersService } from './orders.service';

const ordersService = new OrdersService();

export class OrdersController {
  /**
   * HTTP handler to create a new order from student's cart.
   */
  async createOrder(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { order } = await ordersService.createOrder(userId, req.body);
      return res.status(201).json({
        success: true,
        data: order,
        message: 'Order created successfully. Please complete the payment.',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to pay for a pending order (creates daily Queue, reduces stock).
   */
  async payOrder(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { id } = req.params;
      const { paymentMethod } = req.body;

      const result = await ordersService.processPayment(userId, id, paymentMethod);

      return res.status(200).json({
        success: true,
        data: result,
        message: 'Payment completed successfully. Queue number generated.',
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to fetch student's own order history.
   */
  async getMyOrders(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { status, isPreorder, page, limit } = req.query as any;

      const filters = {
        status,
        isPreorder: isPreorder === 'true' ? true : isPreorder === 'false' ? false : undefined,
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
      };

      const result = await ordersService.getStudentOrders(userId, filters);

      return res.status(200).json({
        success: true,
        data: result.orders,
        pagination: result.pagination,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to view order details.
   */
  async getOrderDetails(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { id } = req.params;

      const order = await ordersService.getOrderDetails(userId, id);

      return res.status(200).json({
        success: true,
        data: order,
      });
    } catch (error) {
      return next(error);
    }
  }

  /**
   * HTTP handler to cancel a pending order.
   */
  async cancelOrder(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.userId;
      const { id } = req.params;

      const order = await ordersService.cancelOrder(userId, id);

      return res.status(200).json({
        success: true,
        data: order,
        message: 'Order cancelled successfully',
      });
    } catch (error) {
      return next(error);
    }
  }
}

export default OrdersController;
