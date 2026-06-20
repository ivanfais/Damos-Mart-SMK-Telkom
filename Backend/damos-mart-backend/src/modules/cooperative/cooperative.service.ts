import prisma from '../../config/database';
import { AppError } from '../../middlewares/error.middleware';

export class CooperativeService {
  /**
   * Fetches active cooperative info (Public/Student).
   */
  async getActiveInfo() {
    return prisma.cooperativeInfo.findMany({
      where: { isActive: true },
    });
  }

  /**
   * Fetches operating hours sorted by day of week.
   */
  async getOperatingHours() {
    return prisma.operatingHour.findMany({
      orderBy: { dayOfWeek: 'asc' },
    });
  }

  /**
   * Fetches crowd levels per hour slot per day.
   */
  async getCrowdData() {
    return prisma.crowdData.findMany({
      orderBy: [
        { dayOfWeek: 'asc' },
        { hourSlot: 'asc' },
      ],
    });
  }

  /**
   * Fetches the real-time cooperative condition set by admin.
   */
  async getCurrentStatus() {
    const status = await prisma.cooperativeStatus.findUnique({
      where: { id: 'default' },
    });

    if (!status) {
      return prisma.cooperativeStatus.create({
        data: { id: 'default', condition: 'NORMAL' },
      });
    }

    return status;
  }

  /**
   * Admin: Updates the real-time cooperative condition.
   */
  async updateCurrentStatus(condition: 'SEPI' | 'NORMAL' | 'RAMAI') {
    const allowed = ['SEPI', 'NORMAL', 'RAMAI'];
    if (!allowed.includes(condition)) {
      throw new AppError(400, 'INVALID_CONDITION', 'Condition must be SEPI, NORMAL, or RAMAI');
    }

    return prisma.cooperativeStatus.upsert({
      where: { id: 'default' },
      update: { condition },
      create: { id: 'default', condition },
    });
  }

  // ==========================================
  // ADMIN METHODS
  // ==========================================

  /**
   * Admin: Creates cooperative information entry.
   */
  async createInfo(data: { title: string; content: string; infoType: string; imageUrl?: string }) {
    return prisma.cooperativeInfo.create({
      data: {
        title: data.title,
        content: data.content,
        infoType: data.infoType,
        imageUrl: data.imageUrl,
        isActive: true,
      },
    });
  }

  /**
   * Admin: Updates cooperative information entry.
   */
  async updateInfo(id: string, data: { title?: string; content?: string; infoType?: string; imageUrl?: string; isActive?: boolean }) {
    const existing = await prisma.cooperativeInfo.findUnique({ where: { id } });
    if (!existing) {
      throw new AppError(404, 'INFO_NOT_FOUND', 'Cooperative info record not found');
    }

    return prisma.cooperativeInfo.update({
      where: { id },
      data,
    });
  }

  /**
   * Admin: Deletes cooperative information entry.
   */
  async deleteInfo(id: string) {
    const existing = await prisma.cooperativeInfo.findUnique({ where: { id } });
    if (!existing) {
      throw new AppError(404, 'INFO_NOT_FOUND', 'Cooperative info record not found');
    }

    await prisma.cooperativeInfo.delete({
      where: { id },
    });
  }

  /**
   * Admin: Bulk updates operating hours.
   */
  async updateOperatingHours(hours: Array<{ id?: string; dayOfWeek: number; openTime: string | null; closeTime: string | null; isClosed: boolean }>) {
    return prisma.$transaction(
      hours.map((hour) => {
        if (hour.id) {
          return prisma.operatingHour.update({
            where: { id: hour.id },
            data: {
              dayOfWeek: hour.dayOfWeek,
              openTime: hour.openTime,
              closeTime: hour.closeTime,
              isClosed: hour.isClosed,
            },
          });
        } else {
          return prisma.operatingHour.create({
            data: {
              dayOfWeek: hour.dayOfWeek,
              openTime: hour.openTime,
              closeTime: hour.closeTime,
              isClosed: hour.isClosed,
            },
          });
        }
      })
    );
  }

  /**
   * Admin: Bulk upserts crowd density slots.
   */
  async updateCrowdData(
    slots: Array<{ dayOfWeek: number; hourSlot: number; avgCrowdLevel: number }>
  ) {
    if (!Array.isArray(slots) || slots.length === 0) {
      throw new AppError(400, 'INVALID_CROWD_DATA', 'Crowd slots payload is required');
    }

    for (const slot of slots) {
      if (
        slot.dayOfWeek < 1 ||
        slot.dayOfWeek > 7 ||
        slot.hourSlot < 0 ||
        slot.hourSlot > 23 ||
        slot.avgCrowdLevel < 1 ||
        slot.avgCrowdLevel > 5
      ) {
        throw new AppError(
          400,
          'INVALID_CROWD_SLOT',
          'Each slot must have dayOfWeek 1-7, hourSlot 0-23, avgCrowdLevel 1-5'
        );
      }
    }

    return prisma.$transaction(
      slots.map((slot) =>
        prisma.crowdData.upsert({
          where: {
            hourSlot_dayOfWeek: {
              hourSlot: slot.hourSlot,
              dayOfWeek: slot.dayOfWeek,
            },
          },
          update: { avgCrowdLevel: slot.avgCrowdLevel },
          create: {
            hourSlot: slot.hourSlot,
            dayOfWeek: slot.dayOfWeek,
            avgCrowdLevel: slot.avgCrowdLevel,
          },
        })
      )
    );
  }
}
export default CooperativeService;
