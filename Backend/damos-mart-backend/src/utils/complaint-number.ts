import { PrismaClient } from '@prisma/client';

/**
 * Generates a unique complaint number formatted as DM-DDMMYY-XXXX
 * (e.g. DM-210526-0009).
 */
export async function generateNextComplaintNumber(prisma: any): Promise<string> {
  const now = new Date();
  const dd = String(now.getDate()).padStart(2, '0');
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const yy = String(now.getFullYear()).slice(-2);
  const dateStr = `${dd}${mm}${yy}`;

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  const count = await prisma.complaint.count({
    where: {
      createdAt: {
        gte: startOfDay,
        lte: endOfDay,
      },
    },
  });

  const nextIndex = count + 1;
  const indexStr = String(nextIndex).padStart(4, '0');
  return `DM-${dateStr}-${indexStr}`;
}

export default generateNextComplaintNumber;
