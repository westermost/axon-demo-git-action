import { test, expect } from '@playwright/test';

test.describe('Basic Tests', () => {
  test('should have correct title', async ({ page }) => {
    await page.goto('https://playwright.dev');
    await expect(page).toHaveTitle(/Playwright/);
  });

  test('should navigate to Getting Started', async ({ page }) => {
    await page.goto('https://playwright.dev');
    await page.getByRole('link', { name: 'Get started' }).click();
    await expect(page).toHaveURL(/.*intro/);
  });

  test('should search documentation', async ({ page }) => {
    await page.goto('https://playwright.dev');
    await page.getByRole('button', { name: 'Search' }).click();
    await page.getByPlaceholder('Search docs').fill('test');
    await expect(page.getByPlaceholder('Search docs')).toHaveValue('test');
  });
});

test.describe('API Tests', () => {
  test('should get successful response', async ({ request }) => {
    const response = await request.get('https://playwright.dev');
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
  });

  test('should have correct content type', async ({ request }) => {
    const response = await request.get('https://playwright.dev');
    const contentType = response.headers()['content-type'];
    expect(contentType).toContain('text/html');
  });
});
