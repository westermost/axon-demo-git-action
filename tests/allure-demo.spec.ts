import { test, expect } from '@playwright/test';
import { allure } from 'allure-playwright';

test.describe('E2E Tests with Allure', () => {
  test('Homepage verification', async ({ page }) => {
    await allure.epic('Web Application');
    await allure.feature('Homepage');
    await allure.story('User visits homepage');
    await allure.severity('critical');

    await allure.step('Navigate to homepage', async () => {
      await page.goto('https://playwright.dev');
    });

    await allure.step('Verify page title', async () => {
      await expect(page).toHaveTitle(/Playwright/);
    });

    await allure.step('Verify main heading', async () => {
      const heading = page.locator('h1').first();
      await expect(heading).toBeVisible();
    });
  });

  test('Navigation test', async ({ page }) => {
    await allure.epic('Web Application');
    await allure.feature('Navigation');
    await allure.story('User navigates through pages');
    await allure.severity('normal');

    await allure.step('Open homepage', async () => {
      await page.goto('https://playwright.dev');
    });

    await allure.step('Click on Docs link', async () => {
      await page.getByRole('link', { name: 'Docs' }).first().click();
    });

    await allure.step('Verify navigation successful', async () => {
      await expect(page).toHaveURL(/.*docs/);
    });
  });

  test('Search functionality', async ({ page }) => {
    await allure.epic('Web Application');
    await allure.feature('Search');
    await allure.story('User searches documentation');
    await allure.severity('normal');

    await page.goto('https://playwright.dev');

    await allure.step('Open search dialog', async () => {
      await page.getByRole('button', { name: 'Search' }).click();
    });

    await allure.step('Enter search query', async () => {
      await page.getByPlaceholder('Search docs').fill('browser');
      await allure.attachment('Search Query', 'browser', 'text/plain');
    });

    await allure.step('Verify search input', async () => {
      await expect(page.getByPlaceholder('Search docs')).toHaveValue('browser');
    });
  });
});

test.describe('API Testing with Allure', () => {
  test('GET request test', async ({ request }) => {
    await allure.epic('API Testing');
    await allure.feature('HTTP Methods');
    await allure.story('GET request validation');
    await allure.severity('critical');

    let response;
    await allure.step('Send GET request', async () => {
      response = await request.get('https://playwright.dev');
    });

    await allure.step('Verify response status', async () => {
      expect(response.ok()).toBeTruthy();
      expect(response.status()).toBe(200);
      await allure.attachment('Status Code', String(response.status()), 'text/plain');
    });

    await allure.step('Verify response headers', async () => {
      const headers = response.headers();
      expect(headers['content-type']).toBeDefined();
    });
  });

  test('Response time test', async ({ request }) => {
    await allure.epic('API Testing');
    await allure.feature('Performance');
    await allure.story('Response time validation');
    await allure.severity('minor');

    const startTime = Date.now();
    
    await allure.step('Send request and measure time', async () => {
      await request.get('https://playwright.dev');
    });

    const endTime = Date.now();
    const responseTime = endTime - startTime;

    await allure.step('Verify response time', async () => {
      await allure.attachment('Response Time', `${responseTime}ms`, 'text/plain');
      expect(responseTime).toBeLessThan(5000);
    });
  });
});
