# Axon Demo - GitHub Actions + AWS SSM

Demo project for running automated tests using **Python**, **pytest**, and **Allure** with GitHub Actions and AWS SSM.

## Tech Stack

- **Language**: Python 3.9
- **Test Framework**: pytest
- **Reporting**: Allure, pytest-html
- **CI/CD**: GitHub Actions
- **Infrastructure**: AWS EC2 + SSM
- **Region**: Singapore (ap-southeast-1)

## Project Structure

```
.
├── tests/
│   └── test_simple.py         # 3 simple pytest tests
├── requirements.txt           # Python dependencies
├── pytest.ini                 # Pytest configuration
├── .github/workflows/
│   ├── test.yml              # Basic workflow (GitHub runners)
│   └── test-aws-ec2.yml      # AWS EC2 workflow (SSM)
└── README.md                  # This file
```

## Quick Start

### Run Tests Locally

```bash
pip install -r requirements.txt
pytest tests/ -v
```

### Run Tests on AWS EC2

1. Setup AWS infrastructure (one-time): See [SETUP_CONSOLE.md](./SETUP_CONSOLE.md)
2. Go to GitHub Actions → "Python Tests on AWS EC2 (SSM)"
3. Click "Run workflow"
4. Enter:
   - **instance_id**: Your EC2 instance ID
   - **s3_bucket**: Your S3 bucket name
5. Wait for completion (~3-5 minutes)

## Workflow Steps

### 1. Setup Environment on EC2
- Install git, pip, Java
- Clone repository
- Install pytest, allure-pytest
- Download Allure commandline

### 2. Run Tests on EC2
- Execute pytest tests
- Generate HTML report
- Upload to S3

### 3. Generate Allure Report
- Generate Allure HTML report from test results

### 4. Upload to S3
- Upload Allure report (HTML + zip)

### 5. Serve Report on EC2
- Start HTTP server on port 8000
- Access report via: `http://<EC2-IP>:8000`

## View Reports

After workflow completes, you have 3 options:

### Option 1: EC2 HTTP Server (Fastest) ⭐
```
http://<EC2-PUBLIC-IP>:8000
```
→ Direct access, no download needed

### Option 2: S3 Online
```
https://<bucket>.s3.ap-southeast-1.amazonaws.com/<run-id>/allure-report/index.html
```

### Option 3: Download and View Locally
```bash
wget https://<bucket>.s3.ap-southeast-1.amazonaws.com/<run-id>/allure-report.tar.gz
tar -xzf allure-report.tar.gz
cd allure-report && python3 -m http.server 8000
```

## Architecture

```
GitHub Actions (OIDC)
    ↓
AWS IAM Role
    ↓
EC2 Instance (SSM - no SSH)
    ↓
Run pytest → Generate Allure → Upload S3 → Serve on port 8000
```

## Security Features

- ✅ No SSH keys required (uses SSM)
- ✅ No long-lived credentials (OIDC)
- ✅ Least privilege IAM roles
- ✅ No port 22 open
- ✅ All commands audited via SSM

## Cost Optimization

- EC2 runs continuously (no auto-stop)
- Remember to **stop EC2 manually** when not in use
- S3 storage: ~1MB per test run

## Setup Documentation

- **Console Setup**: [SETUP_CONSOLE.md](./SETUP_CONSOLE.md) - GUI-based setup
- **CLI Setup**: [SETUP_STEP_BY_STEP.md](./SETUP_STEP_BY_STEP.md) - Command-line setup
- **Quick Start**: [QUICK_START.md](./QUICK_START.md) - Fast setup commands

## Troubleshooting

### Port 8000 not accessible
```bash
# Add security group rule
aws ec2 authorize-security-group-ingress \
  --group-id <sg-id> \
  --protocol tcp \
  --port 8000 \
  --cidr 0.0.0.0/0
```

### Tests not running
- Check setup output for git clone errors
- Verify test files exist in repository
- Check EC2 has internet access

### Allure report empty
- Tests may have failed
- Check pytest output in workflow logs
- Verify allure-pytest is installed

