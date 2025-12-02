# Axon Demo - GitHub Actions + AWS SSM

Demo project for running automated tests using **TypeScript**, **Playwright**, and **Allure** with GitHub Actions and AWS SSM.

## Tech Stack

- **Language**: TypeScript
- **Test Framework**: Playwright
- **Reporting**: Allure, Playwright HTML Reporter
- **CI/CD**: GitHub Actions
- **Infrastructure**: AWS EC2 + SSM

## Project Structure

```
.
├── tests/
│   ├── demo.spec.ts           # Basic Playwright tests
│   └── allure-demo.spec.ts    # Tests with Allure annotations
├── playwright.config.ts       # Playwright configuration
├── tsconfig.json             # TypeScript configuration
├── package.json              # Dependencies
└── README.md                 # This file
```

## Local Setup

### Install Dependencies

```bash
npm install
npx playwright install chromium
```

### Run Tests

```bash
# Run all tests
npm test

# Run with UI mode
npm run test:ui

# Run in headed mode
npm run test:headed

# Show HTML report
npm run report
```

### Generate Allure Report

```bash
# Run tests with Allure
npm test

# Generate Allure report
npm run allure:generate

# Open Allure report
npm run allure:open
```

## Test Features

### Basic Tests (demo.spec.ts)
- ✅ Page navigation
- ✅ Title verification
- ✅ Search functionality
- ✅ API testing

### Allure Tests (allure-demo.spec.ts)
- ✅ Epic/Feature/Story annotations
- ✅ Severity levels
- ✅ Step-by-step execution
- ✅ Attachments
- ✅ Performance testing

## CI/CD Workflow

The GitHub Actions workflow:
1. Starts EC2 instance on-demand
2. Executes Playwright tests via SSM
3. Uploads results to S3
4. Generates Allure reports
5. Stops EC2 instance

## Architecture

- **CI/CD**: GitHub Actions with OIDC authentication
- **Test Runner**: AWS EC2 (Amazon Linux 2023)
- **Execution**: AWS SSM (no SSH required)
- **Storage**: AWS S3 for test results
- **Security**: No long-lived credentials, least privilege IAM roles

