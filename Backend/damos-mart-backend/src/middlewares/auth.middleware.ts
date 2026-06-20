import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken, TokenPayload } from '../utils/jwt';
import { AppError } from './error.middleware';

declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

/**
 * Middleware enforcing authentication using Bearer JWT access tokens.
 * Injects decoded token payload as req.user
 */
export function authMiddleware(req: Request, _res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(
      new AppError(401, 'UNAUTHORIZED', 'Access token is missing or invalid')
    );
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = verifyAccessToken(token);
    req.user = decoded;
    return next();
  } catch (error: any) {
    let msg = 'Invalid access token';
    if (error.name === 'TokenExpiredError') {
      msg = 'Access token has expired';
    }
    return next(new AppError(401, 'UNAUTHORIZED', msg));
  }
}

export default authMiddleware;
