import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service';
import { sendSuccess } from '../../common/response';
import { UserModel } from '../users/user.model';
import { NotFoundError } from '../../common/errors';

export class AuthController {
  static async sendOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { phoneNumber } = req.body;
      const result = await AuthService.sendOtp(phoneNumber);
      sendSuccess(res, result, 'OTP sent successfully');
    } catch (error) {
      next(error);
    }
  }

  static async verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { phoneNumber, otp } = req.body;
      const result = await AuthService.verifyOtp(phoneNumber, otp);
      sendSuccess(res, result, 'Phone verified successfully');
    } catch (error) {
      next(error);
    }
  }

  static async setupProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const user = await AuthService.setupProfile(userId, req.body);
      sendSuccess(res, { user }, 'Profile setup completed');
    } catch (error) {
      next(error);
    }
  }

  static async refreshTokens(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;
      const tokens = await AuthService.refreshTokens(refreshToken);
      sendSuccess(res, tokens, 'Tokens refreshed successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const user = await UserModel.findById(userId);
      if (!user) {
        throw new NotFoundError('User not found');
      }
      sendSuccess(res, { user }, 'Current user profile');
    } catch (error) {
      next(error);
    }
  }

  static async updateSettings(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const user = await UserModel.findByIdAndUpdate(
        userId,
        { $set: req.body },
        { new: true, runValidators: true }
      );
      if (!user) {
        throw new NotFoundError('User not found');
      }
      sendSuccess(res, { user }, 'Settings updated successfully');
    } catch (error) {
      next(error);
    }
  }
}
