"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.corsOptions = void 0;
const cors_1 = __importDefault(require("cors"));
const env_1 = require("./env");
exports.corsOptions = {
    origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps, curl, etc.)
        if (!origin) {
            return callback(null, true);
        }
        // Check if the origin is allowed
        const isAllowed = env_1.env.CORS_ORIGINS.some(allowedOrigin => {
            // Direct match or wildcard match
            if (allowedOrigin === '*')
                return true;
            return origin === allowedOrigin;
        });
        if (isAllowed) {
            callback(null, true);
        }
        else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
};
exports.default = (0, cors_1.default)(exports.corsOptions);
