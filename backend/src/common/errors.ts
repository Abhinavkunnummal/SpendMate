export class AppError extends Error {
  public statusCode: number;
  public errors: any[];
  public isOperational: boolean;

  constructor(message: string, statusCode: number = 400, errors: any[] = []) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(message: string = 'Resource not found') {
    super(message, 404);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized access') {
    super(message, 401);
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Forbidden resource') {
    super(message, 403);
  }
}

export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed', errors: any[] = []) {
    super(message, 422, errors);
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Conflict detected') {
    super(message, 409);
  }
}
