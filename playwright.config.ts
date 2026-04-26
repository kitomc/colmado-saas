import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  retries: 1,
  workers: 1,
  reporter: 'html',
  webServer: {
    command: 'cd flutter-web-admin && flutter run -d web-server --web-port 5173',
    port: 5173,
    timeout: 120_000,
    reuseExistingServer: true,
  },
  use: {
    baseURL: 'http://localhost:5173',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },
  ],
});
