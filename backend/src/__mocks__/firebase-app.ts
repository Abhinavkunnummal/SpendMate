const mockApp = { name: '[DEFAULT]' };
export const initializeApp = (options?: any) => mockApp;
export const getApps = () => [mockApp];
export const cert = (options: any) => options;
export const applicationDefault = () => ({});
export type App = any;
