import { test, expect } from '@playwright/test';
import { waitForFlutterApp } from '../helpers/auth.helpers';

test.describe('App bootstrap — seed', () => {
  test('app loads and redirects to /login', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterApp(page);

    // After Flutter initializes, unauthenticated users should be redirected to /login
    await expect(page).toHaveURL(/\/login/, { timeout: 15_000 });

    // Verify the Flutter canvas is rendered
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });
});
