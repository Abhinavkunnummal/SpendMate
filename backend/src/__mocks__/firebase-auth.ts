export const getAuth = (app?: any) => ({
  verifyIdToken: async (token: string) => {
    if (token === 'valid_firebase_test_token') {
      return {
        uid: 'test_firebase_uid_123',
        phone_number: '+919876543210',
        email: 'test@example.com',
        name: 'Test User',
      };
    }
    throw new Error('Invalid Firebase token');
  },
});
