import express from 'express';
import { createServer } from 'http';
import path from 'path';
import fs from 'fs';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';

import { env } from './config/env';
import { corsOptions } from './config/cors';
import { errorHandler } from './middlewares/error.middleware';
import { initSocket } from './socket';
import { swaggerSpec } from './config/swagger';

// Routers
import authRouter from './modules/auth/auth.routes';
import usersRouter from './modules/users/users.routes';
import categoriesRouter from './modules/categories/categories.routes';
import productsRouter from './modules/products/products.routes';
import cartRouter from './modules/cart/cart.routes';
import ordersRouter from './modules/orders/orders.routes';
import queuesRouter from './modules/queues/queues.routes';
import reviewsRouter from './modules/reviews/reviews.routes';
import chatRouter from './modules/chat/chat.routes';
import coopRouter from './modules/cooperative/cooperative.routes';
import notificationsRouter from './modules/notifications/notifications.routes';
import complaintsRouter from './modules/complaints/complaints.routes';
import adminRouter from './modules/admin/admin.routes';

const app = express();
const server = createServer(app);

// Health check first — Railway probes this before the app is fully warm
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 1. Initialize Socket.IO connection manager
initSocket(server);

// 2. Global Middlewares
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Ensure upload directories exist
const uploadDirs = ['avatars', 'products', 'reviews', 'categories', 'cooperative'];
uploadDirs.forEach((dir) => {
  const dirPath = path.join(env.UPLOAD_DIR, dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
});

// 3. Static Assets serving
app.use('/uploads', express.static(env.UPLOAD_DIR));

// 4. API Routes Registration
const apiPrefix = env.API_PREFIX || '/api/v1';

app.use(`${apiPrefix}/auth`, authRouter);
app.use(`${apiPrefix}/users`, usersRouter);
app.use(`${apiPrefix}/categories`, categoriesRouter);
app.use(`${apiPrefix}/products`, productsRouter);
app.use(`${apiPrefix}/cart`, cartRouter);
app.use(`${apiPrefix}/orders`, ordersRouter);
app.use(`${apiPrefix}/queues`, queuesRouter);
app.use(`${apiPrefix}/reviews`, reviewsRouter);
app.use(`${apiPrefix}/chat`, chatRouter);
app.use(`${apiPrefix}/cooperative`, coopRouter);
app.use(`${apiPrefix}/notifications`, notificationsRouter);
app.use(`${apiPrefix}/complaints`, complaintsRouter);
app.use(`${apiPrefix}/admin`, adminRouter);

// 5. Swagger API Docs Endpoint
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// 6. Global Error Handling Middleware
app.use(errorHandler);

// 7. Start listening
const PORT = env.PORT || 3000;
const HOST = '0.0.0.0';

server.listen(PORT, HOST, () => {
  console.log(`🚀 Damos Mart Backend Server is running on ${HOST}:${PORT}`);
  console.log(`📑 OpenAPI documentation available at http://localhost:${PORT}/api-docs`);
  console.log(`❤️ Health check: http://localhost:${PORT}/health`);
});

export { app, server };
