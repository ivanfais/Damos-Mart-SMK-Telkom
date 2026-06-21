"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CooperativeService = void 0;
const database_1 = __importDefault(require("../../config/database"));
const error_middleware_1 = require("../../middlewares/error.middleware");
class CooperativeService {
    /**
     * Fetches active cooperative info (Public/Student).
     */
    async getActiveInfo() {
        return database_1.default.cooperativeInfo.findMany({
            where: { isActive: true },
        });
    }
    /**
     * Fetches operating hours sorted by day of week.
     */
    async getOperatingHours() {
        return database_1.default.operatingHour.findMany({
            orderBy: { dayOfWeek: 'asc' },
        });
    }
    /**
     * Fetches crowd levels per hour slot per day.
     */
    async getCrowdData() {
        return database_1.default.crowdData.findMany({
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
        const status = await database_1.default.cooperativeStatus.findUnique({
            where: { id: 'default' },
        });
        if (!status) {
            return database_1.default.cooperativeStatus.create({
                data: { id: 'default', condition: 'NORMAL' },
            });
        }
        return status;
    }
    /**
     * Admin: Updates the real-time cooperative condition.
     */
    async updateCurrentStatus(condition) {
        const allowed = ['SEPI', 'NORMAL', 'RAMAI'];
        if (!allowed.includes(condition)) {
            throw new error_middleware_1.AppError(400, 'INVALID_CONDITION', 'Condition must be SEPI, NORMAL, or RAMAI');
        }
        return database_1.default.cooperativeStatus.upsert({
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
    async createInfo(data) {
        return database_1.default.cooperativeInfo.create({
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
    async updateInfo(id, data) {
        const existing = await database_1.default.cooperativeInfo.findUnique({ where: { id } });
        if (!existing) {
            throw new error_middleware_1.AppError(404, 'INFO_NOT_FOUND', 'Cooperative info record not found');
        }
        return database_1.default.cooperativeInfo.update({
            where: { id },
            data,
        });
    }
    /**
     * Admin: Deletes cooperative information entry.
     */
    async deleteInfo(id) {
        const existing = await database_1.default.cooperativeInfo.findUnique({ where: { id } });
        if (!existing) {
            throw new error_middleware_1.AppError(404, 'INFO_NOT_FOUND', 'Cooperative info record not found');
        }
        await database_1.default.cooperativeInfo.delete({
            where: { id },
        });
    }
    /**
     * Admin: Bulk updates operating hours.
     */
    async updateOperatingHours(hours) {
        return database_1.default.$transaction(hours.map((hour) => {
            if (hour.id) {
                return database_1.default.operatingHour.update({
                    where: { id: hour.id },
                    data: {
                        dayOfWeek: hour.dayOfWeek,
                        openTime: hour.openTime,
                        closeTime: hour.closeTime,
                        isClosed: hour.isClosed,
                    },
                });
            }
            else {
                return database_1.default.operatingHour.create({
                    data: {
                        dayOfWeek: hour.dayOfWeek,
                        openTime: hour.openTime,
                        closeTime: hour.closeTime,
                        isClosed: hour.isClosed,
                    },
                });
            }
        }));
    }
    /**
     * Admin: Bulk upserts crowd density slots.
     */
    async updateCrowdData(slots) {
        if (!Array.isArray(slots) || slots.length === 0) {
            throw new error_middleware_1.AppError(400, 'INVALID_CROWD_DATA', 'Crowd slots payload is required');
        }
        for (const slot of slots) {
            if (slot.dayOfWeek < 1 ||
                slot.dayOfWeek > 7 ||
                slot.hourSlot < 0 ||
                slot.hourSlot > 23 ||
                slot.avgCrowdLevel < 1 ||
                slot.avgCrowdLevel > 5) {
                throw new error_middleware_1.AppError(400, 'INVALID_CROWD_SLOT', 'Each slot must have dayOfWeek 1-7, hourSlot 0-23, avgCrowdLevel 1-5');
            }
        }
        return database_1.default.$transaction(slots.map((slot) => database_1.default.crowdData.upsert({
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
        })));
    }
}
exports.CooperativeService = CooperativeService;
exports.default = CooperativeService;
