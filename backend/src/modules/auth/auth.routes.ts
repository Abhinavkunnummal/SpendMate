import { Router } from 'express';
import { AuthController } from './auth.controller';
import { validateRequest } from '../../common/middleware/validate';
import { authenticate } from '../../common/middleware/auth';
import { authRateLimiter } from '../../common/middleware/rate-limiter';
import {
  sendOtpSchema,
  verifyOtpSchema,
  profileSetupSchema,
  refreshTokenSchema,
} from './auth.validation';

const router = Router();

router.post(
  '/send-otp',
  authRateLimiter,
  validateRequest(sendOtpSchema),
  AuthController.sendOtp
);

router.post(
  '/verify-otp',
  authRateLimiter,
  validateRequest(verifyOtpSchema),
  AuthController.verifyOtp
);

router.post(
  '/firebase-session',
  authRateLimiter,
  AuthController.firebaseSession
);

router.post(
  '/profile-setup',
  authenticate,
  validateRequest(profileSetupSchema),
  AuthController.setupProfile
);

router.post(
  '/refresh',
  validateRequest(refreshTokenSchema),
  AuthController.refreshTokens
);

router.get('/me', authenticate, AuthController.getMe);
router.patch('/settings', authenticate, AuthController.updateSettings);

export const authRouter = router;
