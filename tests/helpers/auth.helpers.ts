import { Page, expect } from '@playwright/test';

export async function waitForFlutterApp(page: Page) {
  await page.waitForSelector('flt-glass-pane', { timeout: 20_000 });
  await page.waitForTimeout(1500);
}

export async function fillFlutterInput(page: Page, label: string, value: string) {
  try {
    await page.getByLabel(label).fill(value);
    return;
  } catch {}
  try {
    await page.locator(`flt-semantics[aria-label="${label}"]`).click();
    await page.keyboard.type(value);
    return;
  } catch {}
  await page.getByText(label).click();
  await page.keyboard.type(value);
}

export async function loginCompleto(page: Page, email: string, password: string) {
  await page.goto('/login');
  await waitForFlutterApp(page);
  await fillFlutterInput(page, 'Email', email);
  await fillFlutterInput(page, 'Contraseña', password);
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();
  await expect(page).toHaveURL('/dashboard', { timeout: 15_000 });
}
