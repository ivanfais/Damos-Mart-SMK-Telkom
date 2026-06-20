import { PrismaClient } from '@prisma/client';

/**
 * Generates the next daily queue number (A-001, A-002, etc.)
 * based on the number of queue records created today.
 */
export async function generateNextQueueNumber(prisma: any): Promise<string> {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  // Find the count of queues generated today
  const count = await prisma.queue.count({
    where: {
      createdAt: {
        gte: startOfDay,
        lte: endOfDay,
      },
    },
  });

  const nextNum = count + 1;
  const padded = String(nextNum).padStart(3, '0');
  return `A-${padded}`;
}
export default generateNextQueueNumber;
