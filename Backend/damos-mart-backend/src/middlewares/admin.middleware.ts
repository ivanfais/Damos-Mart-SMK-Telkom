import { Request, Response, NextFunction } from 'express';
import { AppError } from './error.middleware';

/**
 * Middleware restricting access to ADMIN role only.
 * Requires authMiddleware to be registered before.
 */
export function adminMiddleware(req: Request, _res: Response, next: NextFunction) {
  if (!req.user) {
    return next(new AppError(401, 'UNAUTHORIZED', 'Authentication is required'));
  }

  if (req.user.role !== 'ADMIN') {
    return next(
      new AppError(403, 'FORBIDDEN', 'Access denied. Admin role required')
    );
  }

  return next();
}

export default adminMiddleware;
