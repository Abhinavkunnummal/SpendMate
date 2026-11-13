import request from 'supertest';
import { createApp } from '../../app';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';

describe('Authentication & Protected Endpoints Security', () => {
  const app = createApp();

  it('rejects requests to protected endpoints when no token is provided', async () => {
    const res = await request(app).get('/api/v1/wallets');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/No authentication token provided/i);
  });

  it('rejects requests with invalid or malformed tokens', async () => {
    const res = await request(app)
      .get('/api/v1/wallets')
      .set('Authorization', 'Bearer invalid_garbage_token_12345');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Invalid or expired authentication token/i);
  });

  it('rejects requests with expired tokens', async () => {
    const expiredToken = jwt.sign(
      { userId: '507f1f77bcf86cd799439011', phoneNumber: '+919876543210' },
      env.jwtSecret,
      { expiresIn: '-1s' }
    );
    const res = await request(app)
      .get('/api/v1/wallets')
      .set('Authorization', `Bearer ${expiredToken}`);
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/expired/i);
  });

  it('validates Firebase ID tokens through Firebase Admin verifier', async () => {
    const { UserModel } = require('../users/user.model');
    jest.spyOn(UserModel, 'findOne').mockResolvedValue({
      _id: '507f1f77bcf86cd799439011',
      firebaseUid: 'test_firebase_uid_123',
      phoneNumber: '+919876543210',
      name: 'Test User',
    } as any);
    jest.spyOn(UserModel, 'findById').mockResolvedValue({
      _id: '507f1f77bcf86cd799439011',
      firebaseUid: 'test_firebase_uid_123',
      phoneNumber: '+919876543210',
      name: 'Test User',
    } as any);

    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer valid_firebase_test_token');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.phoneNumber).toBe('+919876543210');
  });
});
