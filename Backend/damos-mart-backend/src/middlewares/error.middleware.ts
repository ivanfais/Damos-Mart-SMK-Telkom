import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details: any = null
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

/**
 * Global Express Error Handling Middleware.
 * Standardizes all error responses according to the Damos Mart API design.
 */
export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) {
  // If headers already sent, delegate to default Express handler
  if (res.headersSent) {
    return next(err);
  }

  console.error('💥 Error caught by handler:', err);

  // Zod schema validation errors
  if (err instanceof ZodError) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request input data',
        details: err.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        })),
      },
    });
  }

  // Custom App Error
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        ...(err.details && { details: err.details }),
      },
    });
  }

  // Handle Prisma common error cases (e.g. record not found)
  if (err.code && err.code.startsWith('P')) {
    if (err.code === 'P2002') {
      const target = err.meta?.target || 'field';
      return res.status(409).json({
        success: false,
        error: {
          code: 'CONFLICT_ERROR',
          message: `Record with this ${target} already exists.`,
        },
      });
    }
    
    if (err.code === 'P2025') {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: err.meta?.cause || 'Requested record was not found.',
        },
      });
    }
  }

  // General fallback error
  const statusCode = err.statusCode || 500;
  return res.status(statusCode).json({
    success: false,
    error: {
      code: err.code || 'INTERNAL_SERVER_ERROR',
      message: err.message || 'An unexpected error occurred on the server.',
    },
  });
}

export default errorHandler;
