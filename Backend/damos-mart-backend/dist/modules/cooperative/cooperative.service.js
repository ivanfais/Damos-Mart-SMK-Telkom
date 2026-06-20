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
}
exports.CooperativeService = CooperativeService;
exports.default = CooperativeService;
