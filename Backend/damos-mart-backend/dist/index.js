"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.server = exports.app = void 0;
const express_1 = __importDefault(require("express"));
const http_1 = require("http");
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const cors_1 = __importDefault(require("cors"));
const swagger_ui_express_1 = __importDefault(require("swagger-ui-express"));
const env_1 = require("./config/env");
const cors_2 = require("./config/cors");
const error_middleware_1 = require("./middlewares/error.middleware");
const socket_1 = require("./socket");
const swagger_1 = require("./config/swagger");
// Routers
const auth_routes_1 = __importDefault(require("./modules/auth/auth.routes"));
const users_routes_1 = __importDefault(require("./modules/users/users.routes"));
const categories_routes_1 = __importDefault(require("./modules/categories/categories.routes"));
const products_routes_1 = __importDefault(require("./modules/products/products.routes"));
const cart_routes_1 = __importDefault(require("./modules/cart/cart.routes"));
const orders_routes_1 = __importDefault(require("./modules/orders/orders.routes"));
const queues_routes_1 = __importDefault(require("./modules/queues/queues.routes"));
const reviews_routes_1 = __importDefault(require("./modules/reviews/reviews.routes"));
const chat_routes_1 = __importDefault(require("./modules/chat/chat.routes"));
const cooperative_routes_1 = __importDefault(require("./modules/cooperative/cooperative.routes"));
const notifications_routes_1 = __importDefault(require("./modules/notifications/notifications.routes"));
const complaints_routes_1 = __importDefault(require("./modules/complaints/complaints.routes"));
const favorites_routes_1 = __importDefault(require("./modules/favorites/favorites.routes"));
const admin_routes_1 = __importDefault(require("./modules/admin/admin.routes"));
const app = (0, express_1.default)();
exports.app = app;
const server = (0, http_1.createServer)(app);
exports.server = server;
// 1. Initialize Socket.IO connection manager
(0, socket_1.initSocket)(server);
// 2. Global Middlewares
app.use((0, cors_1.default)(cors_2.corsOptions));
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
// Ensure upload directories exist
const uploadDirs = ['avatars', 'products', 'reviews', 'categories', 'cooperative'];
uploadDirs.forEach((dir) => {
    const dirPath = path_1.default.join(env_1.env.UPLOAD_DIR, dir);
    if (!fs_1.default.existsSync(dirPath)) {
        fs_1.default.mkdirSync(dirPath, { recursive: true });
    }
});
// 3. Static Assets serving
app.use('/uploads', express_1.default.static(env_1.env.UPLOAD_DIR));
// 4. API Routes Registration
const apiPrefix = env_1.env.API_PREFIX || '/api/v1';
app.use(`${apiPrefix}/auth`, auth_routes_1.default);
app.use(`${apiPrefix}/users`, users_routes_1.default);
app.use(`${apiPrefix}/categories`, categories_routes_1.default);
app.use(`${apiPrefix}/products`, products_routes_1.default);
app.use(`${apiPrefix}/cart`, cart_routes_1.default);
app.use(`${apiPrefix}/orders`, orders_routes_1.default);
app.use(`${apiPrefix}/queues`, queues_routes_1.default);
app.use(`${apiPrefix}/reviews`, reviews_routes_1.default);
app.use(`${apiPrefix}/chat`, chat_routes_1.default);
app.use(`${apiPrefix}/cooperative`, cooperative_routes_1.default);
app.use(`${apiPrefix}/notifications`, notifications_routes_1.default);
app.use(`${apiPrefix}/complaints`, complaints_routes_1.default);
app.use(`${apiPrefix}/favorites`, favorites_routes_1.default);
app.use(`${apiPrefix}/admin`, admin_routes_1.default);
// 5. Swagger API Docs Endpoint
app.use('/api-docs', swagger_ui_express_1.default.serve, swagger_ui_express_1.default.setup(swagger_1.swaggerSpec));
// Health check endpoint
app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date() });
});
// 6. Global Error Handling Middleware
app.use(error_middleware_1.errorHandler);
// 7. Start listening
const PORT = env_1.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 Damos Mart Backend Server is running on port ${PORT}`);
    console.log(`📑 OpenAPI documentation available at http://localhost:${PORT}/api-docs`);
});
