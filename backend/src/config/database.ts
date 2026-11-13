import mongoose from 'mongoose';
import { env } from './env';
import { logger } from '../common/logger';

export const connectDatabase = async (): Promise<typeof mongoose | null> => {
  if (env.isTest) {
    logger.info('Test environment detected, skipping default MongoDB connection');
    return null;
  }

  try {
    const conn = await mongoose.connect(env.mongodbUri, {
      autoIndex: true,
      serverSelectionTimeoutMS: 5000,
    });
    logger.info(`MongoDB Connected successfully to ${conn.connection.host}/${conn.connection.name}`);
    return conn;
  } catch (error: any) {
    logger.error('MongoDB connection error:', { message: error.message });
    logger.warn('Running with degraded database connectivity. Ensure MongoDB is running or MONGODB_URI is configured.');
    return null;
  }
};

export const disconnectDatabase = async (): Promise<void> => {
  try {
    await mongoose.disconnect();
    logger.info('MongoDB disconnected cleanly');
  } catch (error: any) {
    logger.error('Error disconnecting MongoDB:', { message: error.message });
  }
};
