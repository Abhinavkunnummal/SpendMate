module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^firebase-admin/app$': '<rootDir>/src/__mocks__/firebase-app.ts',
    '^firebase-admin/auth$': '<rootDir>/src/__mocks__/firebase-auth.ts',
  },
  verbose: true,
  forceExit: true,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
};
