import request from 'supertest';
import { createApp } from './app';

describe('API Foundation & Health Checks', () => {
  const app = createApp();

  it('GET /health returns operational status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.service).toBe('SpendMate Backend API');
  });

  it('GET /api/v1/health returns version and status', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.version).toBe('v1');
  });
});
