import { initializeApp, App, cert, applicationDefault, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { env } from './env';
import { logger } from '../common/logger';

let firebaseApp: App | null = null;

export const initializeFirebase = (): App | null => {
  if (firebaseApp) return firebaseApp;
  const existingApps = typeof getApps === 'function' ? getApps() : [];
  if (existingApps && existingApps.length > 0) {
    firebaseApp = existingApps[0];
    return firebaseApp;
  }

  try {
    if (env.firebase.projectId && env.firebase.privateKey && env.firebase.clientEmail) {
      firebaseApp = initializeApp({
        credential: cert({
          projectId: env.firebase.projectId,
          clientEmail: env.firebase.clientEmail,
          privateKey: env.firebase.privateKey,
        }),
      });
      logger.info('Firebase Admin SDK initialized successfully with service account');
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      firebaseApp = initializeApp({
        credential: applicationDefault(),
      });
      logger.info('Firebase Admin SDK initialized with Google Application Default Credentials');
    } else if (env.firebase.projectId) {
      firebaseApp = initializeApp({
        projectId: env.firebase.projectId,
      });
      logger.info(`Firebase Admin SDK initialized for project: ${env.firebase.projectId}`);
    } else {
      logger.info('Firebase Admin credentials not configured; running in fallback auth mode');
    }
  } catch (error: any) {
    logger.warn(`Firebase Admin SDK initialization notice: ${error.message}`);
  }

  return firebaseApp;
};

export interface VerifiedFirebaseUser {
  uid: string;
  phone_number?: string;
  email?: string;
  name?: string;
}

export const verifyFirebaseToken = async (idToken: string): Promise<VerifiedFirebaseUser | null> => {
  try {
    const app = initializeFirebase();
    if (!app) {
      return null;
    }
    const decodedToken = await getAuth(app).verifyIdToken(idToken);
    return {
      uid: decodedToken.uid,
      phone_number: decodedToken.phone_number,
      email: decodedToken.email,
      name: decodedToken.name,
    };
  } catch (error: any) {
    logger.debug(`Firebase token verification failed: ${error.message}`);
    return null;
  }
};
