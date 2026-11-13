import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { UserModel, IUser } from '../users/user.model';
import { UnauthorizedError, NotFoundError } from '../../common/errors';
import { AuthUserPayload } from '../../common/middleware/auth';
import { logger } from '../../common/logger';

// In-memory OTP storage for rapid verification
const otpStore = new Map<string, { code: string; expiresAt: number }>();

export class AuthService {
  /**
   * Generates or simulates sending a 6-digit OTP to the phone number
   */
  static async sendOtp(phoneNumber: string): Promise<{ message: string; debugOtp?: string }> {
    // Generate a 6-digit OTP (default 123456 in dev/test for seamless developer testing)
    const code = env.nodeEnv === 'production' 
      ? Math.floor(100000 + Math.random() * 900000).toString() 
      : '123456';

    const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes expiry
    otpStore.set(phoneNumber, { code, expiresAt });

    logger.info(`OTP generated for ${phoneNumber}: [${code}]`);

    return {
      message: 'OTP sent successfully to your phone number',
      ...(env.nodeEnv !== 'production' ? { debugOtp: code } : {}),
    };
  }

  /**
   * Verifies OTP and retrieves or provisions user account
   */
  static async verifyOtp(
    phoneNumber: string,
    otp: string
  ): Promise<{ user: IUser; token: string; refreshToken: string; isNewUser: boolean }> {
    const record = otpStore.get(phoneNumber);

    const isDevDefault = (env.nodeEnv !== 'production' && otp === '123456');
    const isValidOtp = (record && record.code === otp && record.expiresAt > Date.now()) || isDevDefault;

    if (!isValidOtp) {
      throw new UnauthorizedError('Invalid or expired OTP code');
    }

    // Clean up used OTP
    otpStore.delete(phoneNumber);

    // Find or create user
    let user = await UserModel.findOne({ phoneNumber });
    let isNewUser = false;

    if (!user) {
      user = await UserModel.create({
        phoneNumber,
        isProfileCompleted: false,
      });
      isNewUser = true;
    }

    const tokens = this.generateTokens(user);

    return {
      user,
      token: tokens.token,
      refreshToken: tokens.refreshToken,
      isNewUser,
    };
  }

  /**
   * Updates user profile during onboarding (Screen 3)
   */
  static async setupProfile(
    userId: string,
    profileData: {
      name: string;
      email?: string;
      avatarUrl?: string;
      currency?: string;
      monthlyBudgetPaise?: number;
      themePreference?: 'light' | 'dark' | 'system';
    }
  ): Promise<IUser> {
    const user = await UserModel.findById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    user.name = profileData.name;
    if (profileData.email) user.email = profileData.email;
    if (profileData.avatarUrl) user.avatarUrl = profileData.avatarUrl;
    if (profileData.currency) user.currency = profileData.currency;
    if (profileData.monthlyBudgetPaise) user.monthlyBudgetPaise = profileData.monthlyBudgetPaise;
    if (profileData.themePreference) user.themePreference = profileData.themePreference;
    user.isProfileCompleted = true;

    await user.save();
    return user;
  }

  /**
   * Refreshes JWT access token
   */
  static async refreshTokens(refreshToken: string): Promise<{ token: string; refreshToken: string }> {
    try {
      const decoded = jwt.verify(refreshToken, env.jwtRefreshSecret) as AuthUserPayload;
      const user = await UserModel.findById(decoded.userId);
      if (!user) {
        throw new UnauthorizedError('User associated with refresh token not found');
      }

      return this.generateTokens(user);
    } catch (error) {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }
  }

  /**
   * Generates JWT token pair
   */
  private static generateTokens(user: IUser): { token: string; refreshToken: string } {
    const payload: AuthUserPayload = {
      userId: user._id.toString(),
      phoneNumber: user.phoneNumber,
      name: user.name,
    };

    const token = jwt.sign(payload, env.jwtSecret, {
      expiresIn: env.jwtExpiresIn as any,
    });

    const refreshToken = jwt.sign(payload, env.jwtRefreshSecret, {
      expiresIn: env.jwtRefreshExpiresIn as any,
    });

    return { token, refreshToken };
  }
}
