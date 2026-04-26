import { test, expect } from '@playwright/test';
import { waitForFlutterApp, fillFlutterInput } from '../helpers/auth.helpers';

test.describe('Register — Registro de usuario', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/register');
    await waitForFlutterApp(page);
  });

  test('1 — Step 1 UI elements are visible', async ({ page }) => {
    // Title / heading
    await expect(page.getByText('Crear cuenta', { exact: false }).first()).toBeVisible();

    // Step indicator
    const stepText = page.getByText(/paso|step|1\s*de\s*2/i);
    await expect(stepText.first()).toBeVisible();

    // Form fields
    await expect(page.getByLabel('Email')).toBeVisible();
    await expect(page.getByLabel('Contraseña')).toBeVisible();
    await expect(page.getByLabel('Confirmar contraseña')).toBeVisible();

    // Buttons
    await expect(page.getByRole('button', { name: /siguiente|continuar|next/i })).toBeVisible();

    // Login link (already have an account)
    const loginLink = page.getByText(/iniciar sesión|loguearse|ya tengo cuenta/i);
    await expect(loginLink.first()).toBeVisible();
  });

  test('2 — Empty fields show validation errors on step 1', async ({ page }) => {
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(1000);

    const errorMsg = page.getByText(/requerido|obligatorio|vacío|required|campo/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('3 — Invalid email format shows error on step 1', async ({ page }) => {
    await fillFlutterInput(page, 'Email', 'notanemail');
    await fillFlutterInput(page, 'Contraseña', 'ValidPass1');
    await fillFlutterInput(page, 'Confirmar contraseña', 'ValidPass1');
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(1000);

    const errorMsg = page.getByText(/email|correo|inválido|válido|@/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('4 — Password without number shows validation error', async ({ page }) => {
    await fillFlutterInput(page, 'Email', 'test@example.com');
    await fillFlutterInput(page, 'Contraseña', 'NoNumbers');
    await fillFlutterInput(page, 'Confirmar contraseña', 'NoNumbers');
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(1000);

    const errorMsg = page.getByText(/número|número|number|dígito|digito/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('5 — Password mismatch shows validation error', async ({ page }) => {
    await fillFlutterInput(page, 'Email', 'test@example.com');
    await fillFlutterInput(page, 'Contraseña', 'ValidPass1');
    await fillFlutterInput(page, 'Confirmar contraseña', 'Different1');
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(1000);

    const errorMsg = page.getByText(/coinciden|coincide|coincidir|mismatch|diferentes|iguales/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('6 — Full registration flow completes to /onboarding', async ({ page }) => {
    // Step 1: valid credentials
    const uniqueEmail = `test-${Date.now()}@colmaria.com`;
    await fillFlutterInput(page, 'Email', uniqueEmail);
    await fillFlutterInput(page, 'Contraseña', 'TestPass123');
    await fillFlutterInput(page, 'Confirmar contraseña', 'TestPass123');
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(1500);

    // Step 2: should show onboarding/profile fields
    await expect(page.getByText(/paso|step|2\s*de\s*2/i).first()).toBeVisible({ timeout: 5_000 });

    // Fill step 2 fields (name, business name, etc.)
    await fillFlutterInput(page, 'Nombre', 'Usuario Test');
    await fillFlutterInput(page, 'Nombre del colmado', 'Colmado Test');
    await fillFlutterInput(page, 'Teléfono', '8095551234');

    // Submit
    await page.getByRole('button', { name: /crear|registrar|finalizar|completar/i }).click();

    // After registration, should land on onboarding or dashboard
    await expect(page).toHaveURL(/\/onboarding|\/dashboard/, { timeout: 15_000 });
  });

  test('7 — Duplicate email shows error', async ({ page }) => {
    // Use a known existing email
    await fillFlutterInput(page, 'Email', 'admin@colmaria.com');
    await fillFlutterInput(page, 'Contraseña', 'TestPass123');
    await fillFlutterInput(page, 'Confirmar contraseña', 'TestPass123');
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(2000);

    const errorMsg = page.getByText(/existente|ya existe|duplicado|duplicate|registered|registrado/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('8 — Step 2 UI shows after valid step 1', async ({ page }) => {
    await fillFlutterInput(page, 'Email', 'step2-test@colmaria.com');
    await fillFlutterInput(page, 'Contraseña', 'ValidPass1');
    await fillFlutterInput(page, 'Confirmar contraseña', 'ValidPass1');
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(1500);

    // Step 2 elements
    await expect(page.getByText(/paso|step|2\s*de\s*2/i).first()).toBeVisible({ timeout: 5_000 });
    await expect(page.getByLabel('Nombre')).toBeVisible();
    await expect(page.getByLabel('Teléfono')).toBeVisible();
  });

  test('9 — Back button returns to step 1 from step 2', async ({ page }) => {
    // Go to step 2 first
    await fillFlutterInput(page, 'Email', 'back-test@colmaria.com');
    await fillFlutterInput(page, 'Contraseña', 'ValidPass1');
    await fillFlutterInput(page, 'Confirmar contraseña', 'ValidPass1');
    await page.getByRole('button', { name: /siguiente|continuar|next/i }).click();
    await page.waitForTimeout(1500);

    // Click back
    await page.getByRole('button', { name: /atrás|back|regresar|volver/i }).click();
    await page.waitForTimeout(1000);

    // Should be back on step 1
    await expect(page.getByLabel('Email')).toBeVisible();
    await expect(page.getByText(/paso|step|1\s*de\s*2/i).first()).toBeVisible();
  });

  test('10 — Register link navigates to /login', async ({ page }) => {
    const loginLink = page.getByText(/iniciar sesión|loguearse|ya tengo cuenta/i);
    await loginLink.first().click();
    await page.waitForTimeout(2000);

    await expect(page).toHaveURL(/\/login/, { timeout: 10_000 });
  });
});
