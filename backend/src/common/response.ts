import { Response } from 'express';

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  meta?: Record<string, any>;
  errors?: any[];
}

export const sendSuccess = <T>(
  res: Response,
  data: T,
  message: string = 'Success',
  statusCode: number = 200,
  meta?: Record<string, any>
): Response => {
  const body: ApiResponse<T> = {
    success: true,
    message,
    data,
    ...(meta ? { meta } : {}),
  };
  return res.status(statusCode).json(body);
};

export const sendError = (
  res: Response,
  message: string = 'Something went wrong',
  statusCode: number = 500,
  errors: any[] = []
): Response => {
  const body: ApiResponse = {
    success: false,
    message,
    errors,
  };
  return res.status(statusCode).json(body);
};
