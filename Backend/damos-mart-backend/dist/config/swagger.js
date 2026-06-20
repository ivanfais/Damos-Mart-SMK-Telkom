"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.swaggerSpec = void 0;
const swagger_jsdoc_1 = __importDefault(require("swagger-jsdoc"));
const env_1 = require("./env");
const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Damos Mart API Docs',
            version: '1.0.0',
            description: 'REST API + WebSocket Server specification for Damos Mart school cooperative digital system.',
            contact: {
                name: 'Developer Team',
                email: 'admin@damosmart.com',
            },
        },
        servers: [
            {
                url: `http://localhost:${env_1.env.PORT}${env_1.env.API_PREFIX}`,
                description: 'Local development server',
            },
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'Enter your JWT access token in the format: Bearer <token>',
                },
            },
        },
        security: [
            {
                bearerAuth: [],
            },
        ],
    },
    apis: [], // We use a pre-composed OpenAPI spec or inline annotations
};
exports.swaggerSpec = (0, swagger_jsdoc_1.default)(options);
// Pre-define common paths for the swagger page for quick manual reference
exports.swaggerSpec.paths = {
    '/auth/register': {
        post: {
            tags: ['Auth'],
            summary: 'Register a new student account',
            requestBody: {
                required: true,
                content: {
                    'application/json': {
                        schema: {
                            type: 'object',
                            properties: {
                                fullName: { type: 'string', example: 'Ivan FP' },
                                email: { type: 'string', example: 'ivan@smktelkom-jkt.sch.id' },
                                phone: { type: 'string', example: '08123456789' },
                                password: { type: 'string', example: 'student123' },
                            },
                            required: ['fullName', 'email', 'password'],
                        },
                    },
                },
            },
            responses: {
                201: { description: 'Registration success' },
                409: { description: 'Email already registered' },
            },
        },
    },
    '/auth/login': {
        post: {
            tags: ['Auth'],
            summary: 'Login using email and password',
            requestBody: {
                required: true,
                content: {
                    'application/json': {
                        schema: {
                            type: 'object',
                            properties: {
                                email: { type: 'string', example: 'admin@damosmart.com' },
                                password: { type: 'string', example: 'admin123' },
                            },
                            required: ['email', 'password'],
                        },
                    },
                },
            },
            responses: {
                200: { description: 'Login successful' },
                401: { description: 'Invalid credentials' },
            },
        },
    },
    '/products': {
        get: {
            tags: ['Products'],
            summary: 'Fetch paginated and filtered catalog',
            parameters: [
                { name: 'category', in: 'query', schema: { type: 'string' } },
                { name: 'search', in: 'query', schema: { type: 'string' } },
                { name: 'inStock', in: 'query', schema: { type: 'string', enum: ['true', 'false'] } },
                { name: 'isPreorder', in: 'query', schema: { type: 'string', enum: ['true', 'false'] } },
                { name: 'sort', in: 'query', schema: { type: 'string', enum: ['newest', 'price_asc', 'price_desc'] } },
                { name: 'page', in: 'query', schema: { type: 'integer' } },
                { name: 'limit', in: 'query', schema: { type: 'integer' } },
            ],
            responses: {
                200: { description: 'Products list retrieved' },
            },
        },
    },
    '/cart': {
        get: {
            tags: ['Cart'],
            summary: 'Get current user cart items',
            responses: {
                200: { description: 'Cart retrieved' },
            },
        },
        post: {
            tags: ['Cart'],
            summary: 'Add item to cart',
            requestBody: {
                required: true,
                content: {
                    'application/json': {
                        schema: {
                            type: 'object',
                            properties: {
                                productId: { type: 'string' },
                                variantId: { type: 'string', nullable: true },
                                quantity: { type: 'integer', default: 1 },
                            },
                            required: ['productId'],
                        },
                    },
                },
            },
            responses: {
                201: { description: 'Added successfully' },
            },
        },
    },
    '/orders': {
        post: {
            tags: ['Orders'],
            summary: 'Checkout cart items and create order',
            requestBody: {
                required: true,
                content: {
                    'application/json': {
                        schema: {
                            type: 'object',
                            properties: {
                                cartItemIds: { type: 'array', items: { type: 'string' } },
                                paymentMethod: { type: 'string', enum: ['QRIS', 'CASH_AT_COUNTER'] },
                                notes: { type: 'string', nullable: true },
                            },
                            required: ['cartItemIds', 'paymentMethod'],
                        },
                    },
                },
            },
            responses: {
                201: { description: 'Order created' },
            },
        },
    },
};
exports.default = exports.swaggerSpec;
