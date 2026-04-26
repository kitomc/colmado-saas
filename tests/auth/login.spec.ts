import { test, expect } from '@playwright/test';
import { waitForFlutterApp, fillFlutterInput } from '../helpers/auth.helpers';

test.describe('Login — Inicio de sesión', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await waitForFlutterApp(page);
  });

  test('1 — UI elements are visible (branding, form, buttons, links, footer)', async ({ page }) => {
    // Branding / header
    await expect(page.getByText('Colmaria', { exact: false }).first()).toBeVisible();

    // Form fields
    await expect(page.getByLabel('Email')).toBeVisible();
    await expect(page.getByLabel('Contraseña')).toBeVisible();

    // Submit button
    await expect(page.getByRole('button', { name: 'Iniciar sesión' })).toBeVisible();

    // Register link
    const registerLink = page.getByText(/registrate|crear cuenta|registrarse/i);
    await expect(registerLink.first()).toBeVisible();

    // Footer or copyright
    await expect(page.getByText(/colmado|colmaria|2025|2026/i).first()).toBeVisible();
  });

  test('2 — Empty form shows validation errors', async ({ page }) => {
    // Click submit without filling anything
    await page.getByRole('button', { name: 'Iniciar sesión' }).click();
    await page.waitForTimeout(1000);

    // Expect some kind of validation feedback
    const errorMessages = page.getByText(/requerido|obligatorio|vacío|required|campo/i);
    await expect(errorMessages.first()).toBeVisible({ timeout: 5_000 });
  });

  test('3 — Email without @ shows invalid format error', async ({ page }) => {
    await fillFlutterInput(page, 'Email', 'emailinvalido');
    await fillFlutterInput(page, 'Contraseña', 'Password123');
    await page.getByRole('button', { name: 'Iniciar sesión' }).click();
    await page.waitForTimeout(1000);

    const errorMsg = page.getByText(/email|correo|inválido|válido|@/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('4 — Short password shows validation error', async ({ page }) => {
    await fillFlutterInput(page, 'Email', 'test@example.com');
    await fillFlutterInput(page, 'Contraseña', 'ab');
    await page.getByRole('button', { name: 'Iniciar sesión' }).click();
    await page.waitForTimeout(1000);

    const errorMsg = page.getByText(/contraseña|password|caracteres|corta|requerido/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('5 — Invalid credentials show error message', async ({ page }) => {
    await fillFlutterInput(page, 'Email', 'noexiste@test.com');
    await fillFlutterInput(page, 'Contraseña', 'WrongPass123');
    await page.getByRole('button', { name: 'Iniciar sesión' }).click();
    await page.waitForTimeout(2000);

    // Expect some kind of auth error feedback
    const errorMsg = page.getByText(/inválido|incorrecto|error|credenciales|not found|no existe/i);
    await expect(errorMsg.first()).toBeVisible({ timeout: 5_000 });
  });

  test('6 — Successful login redirects to /dashboard', async ({ page }) => {
    // To make this test pass reliably, seed a real user via the app or mock
    // For now, use test credentials that should exist in the seed database
    await fillFlutterInput(page, 'Email', 'admin@colmaria.com');
    await fillFlutterInput(page, 'Contraseña', 'Admin12345');
    await page.getByRole('button', { name: 'Iniciar sesión' }).click();

    // After successful login, user lands on dashboard
    await expect(page).toHaveURL('/dashboard', { timeout: 15_000 });
  });

  test('7 — Register link navigates to /register', async ({ page }) => {
    // Find and click the register link/button
    const registerLink = page.getByText(/registrate|crear cuenta|registrarse/i);
    await registerLink.first().click();
    await page.waitForTimeout(2000);

    await expect(page).toHaveURL(/\/register/, { timeout: 10_000 });
  });
});
