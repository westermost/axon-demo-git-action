# Axon Demo - GitHub Actions + AWS SSM

Demo project for running automated tests using **Python**, **pytest**, and **Allure** with GitHub Actions and AWS SSM.

## Tech Stack

- **Language**: Python 3.11
- **Test Framework**: pytest
- **Reporting**: Allure, pytest-html
- **CI/CD**: GitHub Actions
- **Infrastructure**: AWS EC2 + SSM

## Project Structure

```
.
├── tests/
│   ├── test_demo.py           # Basic pytest tests
│   └── test_allure_demo.py    # Tests with Allure annotations
├── requirements.txt           # Python dependencies
├── pytest.ini                 # Pytest configuration
└── README.md                  # This file
```

## Local Setup

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Run Tests

```bash
# Run all tests
pytest tests/ -v

# Generate HTML report
pytest tests/ --html=report.html --self-contained-html

# Generate Allure results
pytest tests/ --alluredir=allure-results
```

## Test Features

### Basic Tests (test_demo.py)
- ✅ Math operations
- ✅ String operations
- ✅ List operations
- ✅ Parametrized tests

### Allure Tests (test_allure_demo.py)
- ✅ Epic/Feature/Story annotations
- ✅ Severity levels
- ✅ Step-by-step execution
- ✅ Attachments
- ✅ API testing

## CI/CD Workflow

The GitHub Actions workflow:
1. Starts EC2 instance on-demand
2. Executes pytest tests via SSM
3. Uploads results to S3
4. Generates test reports
5. Stops EC2 instance

## Architecture

- **CI/CD**: GitHub Actions with OIDC authentication
- **Test Runner**: AWS EC2 (Amazon Linux 2023)
- **Execution**: AWS SSM (no SSH required)
- **Storage**: AWS S3 for test results
- **Security**: No long-lived credentials, least privilege IAM roles

