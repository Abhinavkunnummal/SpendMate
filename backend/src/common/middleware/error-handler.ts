import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors';
import { sendError } from '../response';
import { logger } from '../logger';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  logger.error(`Error on ${req.method} ${req.url}:`, {
    message: err.message,
    stack: process.env.NODE_ENV !== 'production' ? err.stack : undefined,
  });

  if (err instanceof AppError) {
    sendError(res, err.message, err.statusCode, err.errors);
    return;
  }

  // Handle Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue || {})[0] || 'field';
    sendError(res, `Duplicate value entered for ${field}`, 409);
    return;
  }

  // Handle Mongoose CastError (invalid ObjectId)
  if (err.name === 'CastError') {
    sendError(res, `Invalid resource identifier: ${err.value}`, 400);
    return;
  }

  // Handle Zod or generic validation error
  if (err.name === 'ValidationError') {
    sendError(res, err.message, 422, err.errors || []);
    return;
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    sendError(res, 'Invalid authentication token', 401);
    return;
  }
  if (err.name === 'TokenExpiredError') {
    sendError(res, 'Authentication token has expired', 401);
    return;
  }

  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production' && statusCode === 500
    ? 'Internal Server Error'
    : err.message || 'Something went wrong';

  sendError(res, message, statusCode);
};
