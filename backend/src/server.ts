import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { createApp } from './app';
import { env } from './config/env';
import { connectDatabase, disconnectDatabase } from './config/database';
import { logger } from './common/logger';

const startServer = async () => {
  const app = createApp();
  const server = http.createServer(app);

  // Initialize Socket.IO
  const io = new SocketIOServer(server, {
    cors: {
      origin: env.corsOrigin === '*' ? true : env.corsOrigin,
      methods: ['GET', 'POST'],
      credentials: true,
    },
  });

  // Socket.IO connection handling
  io.on('connection', (socket) => {
    logger.info(`Socket connected: ${socket.id}`);

    // Join user room for private notifications
    socket.on('join_user_room', (userId: string) => {
      if (userId) {
        socket.join(`user:${userId}`);
        logger.debug(`Socket ${socket.id} joined user room: user:${userId}`);
      }
    });

    // Join trip room for live group expenses & settlements
    socket.on('join_trip_room', (tripId: string) => {
      if (tripId) {
        socket.join(`trip:${tripId}`);
        logger.debug(`Socket ${socket.id} joined trip room: trip:${tripId}`);
      }
    });

    socket.on('leave_trip_room', (tripId: string) => {
      if (tripId) {
        socket.leave(`trip:${tripId}`);
        logger.debug(`Socket ${socket.id} left trip room: trip:${tripId}`);
      }
    });

    socket.on('disconnect', () => {
      logger.info(`Socket disconnected: ${socket.id}`);
    });
  });

  // Connect to Database
  await connectDatabase();

  // Listen
  server.listen(env.port, '0.0.0.0', () => {
    logger.info(`SpendMate Server running in ${env.nodeEnv} mode on http://0.0.0.0:${env.port}`);
    logger.info(`Health check available at http://localhost:${env.port}/api/${env.apiVersion}/health`);
  });

  // Graceful shutdown
  const handleShutdown = async (signal: string) => {
    logger.info(`Received ${signal}. Gracefully shutting down SpendMate server...`);
    server.close(async () => {
      await disconnectDatabase();
      logger.info('Closed out remaining connections.');
      process.exit(0);
    });

    setTimeout(() => {
      logger.error('Could not close connections in time, forcefully shutting down');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', () => handleShutdown('SIGTERM'));
  process.on('SIGINT', () => handleShutdown('SIGINT'));

  return { app, server, io };
};

if (process.env.NODE_ENV !== 'test') {
  startServer().catch((err) => {
    logger.error('Failed to start server:', { message: err.message });
    process.exit(1);
  });
}

export { startServer };
