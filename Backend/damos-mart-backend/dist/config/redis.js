"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isRedisConnected = exports.redisClient = void 0;
exports.getCache = getCache;
exports.setCache = setCache;
exports.deleteCache = deleteCache;
const redis_1 = require("redis");
const env_1 = require("./env");
const redisClient = (0, redis_1.createClient)({
    url: env_1.env.REDIS_URL,
});
exports.redisClient = redisClient;
let isRedisConnected = false;
exports.isRedisConnected = isRedisConnected;
redisClient.on('error', (err) => {
    console.warn('⚠️ Redis Client Error:', err.message || err);
});
redisClient.on('connect', () => {
    exports.isRedisConnected = isRedisConnected = true;
    console.log('🔌 Redis client connecting...');
});
redisClient.on('ready', () => {
    exports.isRedisConnected = isRedisConnected = true;
    console.log('🚀 Redis client ready');
});
redisClient.on('end', () => {
    exports.isRedisConnected = isRedisConnected = false;
    console.log('🔌 Redis client disconnected');
});
// Handle connect asynchronously
(async () => {
    try {
        await redisClient.connect();
    }
    catch (err) {
        console.warn('⚠️ Redis connection failed. The application will run, but cache operations will be bypassed.');
    }
})();
/**
 * Robust wrapper to get from redis with fallback
 */
async function getCache(key) {
    if (!isRedisConnected)
        return null;
    try {
        return await redisClient.get(key);
    }
    catch {
        return null;
    }
}
/**
 * Robust wrapper to set to redis with fallback
 */
async function setCache(key, value, expirySeconds) {
    if (!isRedisConnected)
        return;
    try {
        if (expirySeconds) {
            await redisClient.set(key, value, { EX: expirySeconds });
        }
        else {
            await redisClient.set(key, value);
        }
    }
    catch (err) {
        console.warn(`Failed to set redis cache for key: ${key}`);
    }
}
/**
 * Robust wrapper to delete from redis
 */
async function deleteCache(key) {
    if (!isRedisConnected)
        return;
    try {
        await redisClient.del(key);
    }
    catch (err) {
        console.warn(`Failed to delete redis cache for key: ${key}`);
    }
}
