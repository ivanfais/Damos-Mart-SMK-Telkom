import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';

type ComplaintCategory = 'PRODUCT' | 'SERVICE' | 'ORDER' | 'QUEUE' | 'OTHER';
type ComplaintStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'REJECTED';
type ComplaintPriority = 'LOW' | 'MEDIUM' | 'HIGH';

const userSelect = {
  id: true,
  fullName: true,
  email: true,
  phone: true,
} as const;

const orderSelect = {
  id: true,
  orderNumber: true,
  total: true,
  status: true,
} as const;

export class ComplaintsService {
  /**
   * Student: creates a complaint tied to their account.
   */
  async create(
    userId: string | null,
    data: {
      subject: string;
      description: string;
      category?: ComplaintCategory;
      priority?: ComplaintPriority;
      orderId?: string | null;
    }
  ) {
    if (data.orderId) {
      const order = await prisma.order.findUnique({ where: { id: data.orderId } });
      if (!order) {
        throw new AppError(404, 'ORDER_NOT_FOUND', 'Pesanan terkait tidak ditemukan');
      }
    }

    return prisma.complaint.create({
      data: {
        userId: userId ?? undefined,
        orderId: data.orderId ?? undefined,
        subject: data.subject,
        description: data.description,
        category: (data.category ?? 'OTHER') as any,
        priority: (data.priority ?? 'MEDIUM') as any,
      },
      include: { user: { select: userSelect }, order: { select: orderSelect } },
    });
  }

  /**
   * Student: fetches complaints they submitted.
   */
  async getByUser(userId: string) {
    return prisma.complaint.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { order: { select: orderSelect } },
    });
  }

  // ==========================================
  // ADMIN METHODS
  // ==========================================

  /**
   * Admin: paginated list with search + status/category/priority filters.
   */
  async getAllAdmin(filters: {
    status?: ComplaintStatus;
    category?: ComplaintCategory;
    priority?: ComplaintPriority;
    search?: string;
    page: number;
    limit: number;
  }) {
    const { status, category, priority, search, page, limit } = filters;
    const offset = (page - 1) * limit;

    const where: any = {};
    if (status) where.status = status;
    if (category) where.category = category;
    if (priority) where.priority = priority;
    if (search) {
      where.OR = [
        { subject: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { user: { fullName: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const [complaints, totalItems] = await Promise.all([
      prisma.complaint.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
        include: { user: { select: userSelect }, order: { select: orderSelect } },
      }),
      prisma.complaint.count({ where }),
    ]);

    const totalPages = Math.ceil(totalItems / limit) || 1;
    return {
      complaints,
      pagination: { page, limit, totalItems, totalPages },
    };
  }

  /**
   * Admin: aggregate counts for dashboard cards.
   */
  async getStats() {
    const [total, open, inProgress, resolved, rejected] = await Promise.all([
      prisma.complaint.count(),
      prisma.complaint.count({ where: { status: 'OPEN' } }),
      prisma.complaint.count({ where: { status: 'IN_PROGRESS' } }),
      prisma.complaint.count({ where: { status: 'RESOLVED' } }),
      prisma.complaint.count({ where: { status: 'REJECTED' } }),
    ]);
    return { total, open, inProgress, resolved, rejected };
  }

  /**
   * Admin: get a single complaint with relations.
   */
  async getById(id: string) {
    const complaint = await prisma.complaint.findUnique({
      where: { id },
      include: { user: { select: userSelect }, order: { select: orderSelect } },
    });
    if (!complaint) {
      throw new AppError(404, 'COMPLAINT_NOT_FOUND', 'Komplain tidak ditemukan');
    }
    return complaint;
  }

  /**
   * Admin: updates status and/or priority. Sets resolvedAt when resolved.
   */
  async updateStatus(id: string, data: { status?: ComplaintStatus; priority?: ComplaintPriority }) {
    await this.getById(id);

    const patch: any = {};
    if (data.priority) patch.priority = data.priority;
    if (data.status) {
      patch.status = data.status;
      patch.resolvedAt =
        data.status === 'RESOLVED' || data.status === 'REJECTED' ? new Date() : null;
    }

    return prisma.complaint.update({
      where: { id },
      data: patch,
      include: { user: { select: userSelect }, order: { select: orderSelect } },
    });
  }

  /**
   * Admin: writes an official response. Optionally moves the status forward.
   */
  async respond(id: string, data: { adminResponse: string; status?: ComplaintStatus }) {
    await this.getById(id);

    const patch: any = {
      adminResponse: data.adminResponse,
      respondedAt: new Date(),
    };
    if (data.status) {
      patch.status = data.status;
      patch.resolvedAt =
        data.status === 'RESOLVED' || data.status === 'REJECTED' ? new Date() : null;
    } else {
      // Default: move an untouched complaint into IN_PROGRESS once replied.
      patch.status = 'IN_PROGRESS';
    }

    return prisma.complaint.update({
      where: { id },
      data: patch,
      include: { user: { select: userSelect }, order: { select: orderSelect } },
    });
  }

  /**
   * Admin: deletes a complaint.
   */
  async remove(id: string) {
    await this.getById(id);
    await prisma.complaint.delete({ where: { id } });
  }
}

export default ComplaintsService;
