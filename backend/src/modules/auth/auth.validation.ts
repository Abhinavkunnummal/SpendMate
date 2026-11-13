import { z } from 'zod';

export const sendOtpSchema = z.object({
  body: z.object({
    phoneNumber: z
      .string()
      .min(10, 'Phone number must be at least 10 characters')
      .max(15, 'Phone number too long')
      .regex(/^\+?[1-9]\d{1,14}$/, 'Invalid international phone number format'),
  }),
});

export const verifyOtpSchema = z.object({
  body: z.object({
    phoneNumber: z.string().min(10),
    otp: z.string().length(6, 'OTP must be 6 digits'),
  }),
});

export const profileSetupSchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Invalid email address').optional(),
    avatarUrl: z.string().url('Invalid avatar URL').optional(),
    currency: z.string().length(3).default('INR'),
    monthlyBudgetPaise: z.number().int().positive().optional(),
    themePreference: z.enum(['light', 'dark', 'system']).default('system'),
  }),
});

export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token is required'),
  }),
});
