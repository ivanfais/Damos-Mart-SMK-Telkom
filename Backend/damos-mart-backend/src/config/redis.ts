import { createClient } from 'redis';
import { env } from './env';

const redisClient = createClient({
  url: env.REDIS_URL,
});

let isRedisConnected = false;

redisClient.on('error', (err) => {
  console.warn('⚠️ Redis Client Error:', err.message || err);
});

redisClient.on('connect', () => {
  isRedisConnected = true;
  console.log('🔌 Redis client connecting...');
});

redisClient.on('ready', () => {
  isRedisConnected = true;
  console.log('🚀 Redis client ready');
});

redisClient.on('end', () => {
  isRedisConnected = false;
  console.log('🔌 Redis client disconnected');
});

// Handle connect asynchronously
(async () => {
  try {
    await redisClient.connect();
  } catch (err) {
    console.warn('⚠️ Redis connection failed. The application will run, but cache operations will be bypassed.');
  }
})();

/**
 * Robust wrapper to get from redis with fallback
 */
export async function getCache(key: string): Promise<string | null> {
  if (!isRedisConnected) return null;
  try {
    return await redisClient.get(key);
  } catch {
    return null;
  }
}

/**
 * Robust wrapper to set to redis with fallback
 */
export async function setCache(key: string, value: string, expirySeconds?: number): Promise<void> {
  if (!isRedisConnected) return;
  try {
    if (expirySeconds) {
      await redisClient.set(key, value, { EX: expirySeconds });
    } else {
      await redisClient.set(key, value);
    }
  } catch (err) {
    console.warn(`Failed to set redis cache for key: ${key}`);
  }
}

/**
 * Robust wrapper to delete from redis
 */
export async function deleteCache(key: string): Promise<void> {
  if (!isRedisConnected) return;
  try {
    await redisClient.del(key);
  } catch (err) {
    console.warn(`Failed to delete redis cache for key: ${key}`);
  }
}

export { redisClient, isRedisConnected };
