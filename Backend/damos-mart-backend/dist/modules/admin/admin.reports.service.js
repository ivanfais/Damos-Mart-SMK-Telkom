"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminReportsService = void 0;
const database_1 = __importDefault(require("../../config/database"));
class AdminReportsService {
    /**
     * Generates sales metrics, top selling products, and category-wise distributions.
     */
    async getSalesReport(period) {
        const now = new Date();
        let startDate = new Date();
        // 1. Determine filter interval
        if (period === 'daily') {
            // Last 7 days
            startDate.setDate(now.getDate() - 7);
        }
        else if (period === 'weekly') {
            // Last 4 weeks
            startDate.setDate(now.getDate() - 28);
        }
        else {
            // Monthly: Last 12 months
            startDate.setMonth(now.getMonth() - 12);
        }
        // 2. Fetch completed/paid orders in range
        const orders = await database_1.default.order.findMany({
            where: {
                paymentStatus: 'PAID',
                createdAt: { gte: startDate },
            },
            include: {
                orderItems: {
                    include: {
                        product: {
                            include: {
                                category: true,
                            },
                        },
                    },
                },
            },
            orderBy: { createdAt: 'asc' },
        });
        const totalOrders = orders.length;
        const totalRevenue = orders.reduce((sum, ord) => sum + Number(ord.total), 0);
        // Calculate daily average
        const millisecondsDiff = now.getTime() - startDate.getTime();
        const daysDiff = Math.max(1, Math.ceil(millisecondsDiff / (1000 * 60 * 60 * 24)));
        const averageSalesPerDay = totalRevenue / daysDiff;
        // 3. Build sales chart entries
        const salesChartMap = new Map();
        orders.forEach((order) => {
            let key = '';
            const date = order.createdAt;
            if (period === 'daily') {
                // e.g. YYYY-MM-DD
                key = date.toISOString().split('T')[0];
            }
            else if (period === 'weekly') {
                // e.g. Week number
                const oneJan = new Date(date.getFullYear(), 0, 1);
                const numberOfDays = Math.floor((date.getTime() - oneJan.getTime()) / (24 * 60 * 60 * 1000));
                const weekNum = Math.ceil((date.getDay() + 1 + numberOfDays) / 7);
                key = `${date.getFullYear()}-W${weekNum}`;
            }
            else {
                // e.g. YYYY-MM
                key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
            }
            const existing = salesChartMap.get(key) || { dateStr: key, revenue: 0, volume: 0 };
            existing.revenue += Number(order.total);
            existing.volume += 1;
            salesChartMap.set(key, existing);
        });
        const salesChart = Array.from(salesChartMap.values());
        // 4. Build top selling products
        const productStatsMap = new Map();
        orders.forEach((order) => {
            order.orderItems.forEach((item) => {
                const key = item.productId;
                const price = Number(item.productPrice);
                const subtotal = Number(item.subtotal);
                const existing = productStatsMap.get(key) || {
                    id: item.productId,
                    name: item.productName,
                    categoryName: item.product.category.name,
                    quantitySold: 0,
                    totalRevenue: 0,
                };
                existing.quantitySold += item.quantity;
                existing.totalRevenue += subtotal;
                productStatsMap.set(key, existing);
            });
        });
        const topProducts = Array.from(productStatsMap.values())
            .sort((a, b) => b.quantitySold - a.quantitySold)
            .slice(0, 10);
        // 5. Build category-wise distribution
        const categoryStatsMap = new Map();
        orders.forEach((order) => {
            order.orderItems.forEach((item) => {
                const key = item.product.category.name;
                const subtotal = Number(item.subtotal);
                const existing = categoryStatsMap.get(key) || {
                    categoryName: key,
                    revenue: 0,
                    quantitySold: 0,
                };
                existing.revenue += subtotal;
                existing.quantitySold += item.quantity;
                categoryStatsMap.set(key, existing);
            });
        });
        const salesByCategory = Array.from(categoryStatsMap.values());
        return {
            summary: {
                totalRevenue,
                totalOrders,
                averageSalesPerDay,
            },
            salesChart,
            topProducts,
            salesByCategory,
        };
    }
}
exports.AdminReportsService = AdminReportsService;
exports.default = AdminReportsService;
