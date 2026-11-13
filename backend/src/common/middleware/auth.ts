import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { UnauthorizedError } from '../errors';
import { UserModel } from '../../modules/users/user.model';
import { verifyFirebaseToken } from '../../config/firebase';

export interface AuthUserPayload {
  userId: string;
  phoneNumber: string;
  name?: string;
  firebaseUid?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUserPayload;
    }
  }
}

export const authenticate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new UnauthorizedError('No authentication token provided'));
  }

  const token = authHeader.split(' ')[1];

  // 1. First attempt: Verify SpendMate App JWT
  try {
    const decoded = jwt.verify(token, env.jwtSecret) as AuthUserPayload;
    req.user = decoded;
    return next();
  } catch (jwtError: any) {
    // If not valid SpendMate JWT, attempt Firebase ID Token verification
    if (jwtError.name === 'TokenExpiredError') {
      return next(new UnauthorizedError('Authentication token has expired'));
    }
  }

  // 2. Second attempt: Verify Firebase ID Token via Firebase Admin SDK
  try {
    const firebaseUser = await verifyFirebaseToken(token);
    if (firebaseUser) {
      const firebaseUid = firebaseUser.uid;

      // Identify user securely using verified Firebase UID from MongoDB Atlas
      let user = await UserModel.findOne({ firebaseUid });

      // If user not found by firebaseUid, look up by phone number if present
      if (!user && firebaseUser.phone_number) {
        user = await UserModel.findOne({ phoneNumber: firebaseUser.phone_number });
        if (user) {
          user.firebaseUid = firebaseUid;
          await user.save();
        }
      }

      // If user does not exist in MongoDB, provision user record
      if (!user) {
        user = await UserModel.create({
          firebaseUid,
          phoneNumber: firebaseUser.phone_number || '',
          email: firebaseUser.email,
          name: firebaseUser.name || '',
          isProfileCompleted: false,
        });
      }

      // Never trust client-supplied user ID; bind server verified ID
      req.user = {
        userId: user._id.toString(),
        phoneNumber: user.phoneNumber,
        name: user.name,
        firebaseUid: user.firebaseUid,
      };

      return next();
    }
  } catch (firebaseErr: any) {
    // Fall through to unauthorized
  }

  return next(new UnauthorizedError('Invalid or expired authentication token'));
};
