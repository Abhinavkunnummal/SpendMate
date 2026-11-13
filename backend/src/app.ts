import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env';
import { errorHandler } from './common/middleware/error-handler';
import { apiRateLimiter } from './common/middleware/rate-limiter';
import { sendSuccess } from './common/response';

export const createApp = (): Application => {
  const app = express();

  // Security Headers
  app.use(helmet());

  // CORS Setup
  app.use(
    cors({
      origin: env.corsOrigin === '*' ? true : env.corsOrigin,
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
    })
  );

  // Request body parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // HTTP Logging (omit in test)
  if (!env.isTest) {
    app.use(morgan('combined'));
  }

  // Rate Limiting on API routes
  app.use(`/api/${env.apiVersion}`, apiRateLimiter);

  // Health Check Endpoint
  app.get('/health', (req: Request, res: Response) => {
    sendSuccess(res, {
      status: 'UP',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      service: 'SpendMate Backend API',
      version: '1.0.0',
    }, 'SpendMate API is operational');
  });

  app.get(`/api/${env.apiVersion}/health`, (req: Request, res: Response) => {
    sendSuccess(res, {
      status: 'UP',
      version: env.apiVersion,
      environment: env.nodeEnv,
      timestamp: new Date().toISOString(),
    }, 'SpendMate API v1 is healthy');
  });

  // Authentication & Users Route
  const { authRouter } = require('./modules/auth/auth.routes');
  app.use(`/api/${env.apiVersion}/auth`, authRouter);

  // Personal Finance Routes
  const { walletRouter } = require('./modules/wallets/wallet.routes');
  const { categoryRouter } = require('./modules/categories/category.routes');
  const { transactionRouter } = require('./modules/transactions/transaction.routes');
  const { budgetRouter } = require('./modules/budgets/budget.routes');
  const { savingsRouter } = require('./modules/savings/savings.routes');
  const { analyticsRouter } = require('./modules/analytics/analytics.routes');

  app.use(`/api/${env.apiVersion}/wallets`, walletRouter);
  app.use(`/api/${env.apiVersion}/categories`, categoryRouter);
  app.use(`/api/${env.apiVersion}/transactions`, transactionRouter);
  app.use(`/api/${env.apiVersion}/budgets`, budgetRouter);
  app.use(`/api/${env.apiVersion}/savings`, savingsRouter);
  app.use(`/api/${env.apiVersion}/analytics`, analyticsRouter);

  // Trips & Group Expenses Routes
  const { tripRouter } = require('./modules/trips/trip.routes');
  const { tripExpenseRouter } = require('./modules/trip_expenses/trip-expense.routes');
  const { settlementRouter } = require('./modules/settlements/settlement.routes');

  app.use(`/api/${env.apiVersion}/trips`, tripRouter);
  app.use(`/api/${env.apiVersion}/trip-expenses`, tripExpenseRouter);
  app.use(`/api/${env.apiVersion}/settlements`, settlementRouter);

  // Smart Financial Features
  const { receiptRouter } = require('./modules/receipts/receipt.routes');
  const { aiAssistantRouter } = require('./modules/ai_assistant/ai-assistant.routes');
  const { recurringRouter } = require('./modules/recurring_expenses/recurring.routes');
  const { notificationRouter } = require('./modules/notifications/notification.routes');

  app.use(`/api/${env.apiVersion}/receipts`, receiptRouter);
  app.use(`/api/${env.apiVersion}/ai-assistant`, aiAssistantRouter);
  app.use(`/api/${env.apiVersion}/recurring-expenses`, recurringRouter);
  app.use(`/api/${env.apiVersion}/notifications`, notificationRouter);

  // Offline Delta Sync Route
  const { syncRouter } = require('./modules/sync/sync.routes');
  app.use(`/api/${env.apiVersion}/sync`, syncRouter);

  // Central Error Handler
  app.use(errorHandler);

  return app;
};
