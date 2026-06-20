import { PrismaClient } from '@prisma/client';

/**
 * Generates a unique order number formatted as ORD-YYYYMMDD-XXX
 * (e.g. ORD-20260116-001).
 */
export async function generateNextOrderNumber(prisma: any): Promise<string> {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const dateStr = `${yyyy}${mm}${dd}`;

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  const count = await prisma.order.count({
    where: {
      createdAt: {
        gte: startOfDay,
        lte: endOfDay,
      },
    },
  });

  const nextIndex = count + 1;
  const indexStr = String(nextIndex).padStart(3, '0');
  return `ORD-${dateStr}-${indexStr}`;
}
export default generateNextOrderNumber;
