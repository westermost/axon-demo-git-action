# Project Summary

## 📁 Documentation Files

| File | Purpose | When to Use |
|------|---------|-------------|
| **QUICK_REFERENCE.md** | Commands & URLs cheat sheet | 👉 Dùng hàng ngày |
| **SETUP_CONSOLE.md** | Setup qua AWS Console (GUI) | Lần đầu setup, không dùng CLI |
| **QUICK_START.md** | 5-minute setup commands | Setup nhanh với AWS CLI |
| **SETUP_STEP_BY_STEP.md** | Chi tiết từng bước CLI | Prefer command line |
| **WORKFLOW_GUIDE.md** | Giải thích workflows | Hiểu cách workflows hoạt động |
| **README.md** | Project overview | Tổng quan project |

## 🎯 Current Workflow

### Workflow: Python Tests on AWS EC2 (SSM)

**Trigger**: Manual (workflow_dispatch)

**Steps**:
1. **Setup Environment** (~2 min)
   - Install git, pip, Java
   - Clone repository
   - Install pytest, allure-pytest
   - Download Allure CLI

2. **Run Tests** (~30 sec)
   - Execute 3 pytest tests
   - Generate HTML report
   - Upload to S3

3. **Generate Allure Report** (~10 sec)
   - Create Allure HTML report

4. **Upload to S3** (~5 sec)
   - Upload Allure HTML (viewable online)
   - Upload Allure zip (downloadable)

5. **Serve on EC2** (~1 sec)
   - Start HTTP server on port 8000
   - Access: `http://<EC2-IP>:8000`

**Total Time**: ~3-4 minutes

## 🧪 Tests

- **test_simple.py**: 3 basic tests
  - test_simple: 1 + 1 = 2
  - test_hello: String uppercase
  - test_math: Math operations

**Total**: 3 tests, 100% pass rate

## 📊 View Reports

### Option 1: EC2 HTTP Server (Fastest) ⭐
```
http://<EC2-PUBLIC-IP>:8000
```
- No download needed
- Direct access
- Requires port 8000 open

### Option 2: S3 Online
```
https://kiemtraxe.s3.ap-southeast-1.amazonaws.com/<run-id>/allure-report/index.html
```
- Permanent storage
- No EC2 needed

### Option 3: Pytest HTML
```
https://kiemtraxe.s3.ap-southeast-1.amazonaws.com/<run-id>/report.html
```
- Simple HTML report
- Self-contained

## 🚀 Quick Commands

### Run Workflow
```
GitHub Actions → "Python Tests on AWS EC2 (SSM)" → Run workflow
```

### Get EC2 IP
```bash
aws ec2 describe-instances --instance-ids i-0cd39c0cf451a83cc \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

### Open Port 8000
```bash
aws ec2 authorize-security-group-ingress --group-id <sg-id> \
  --protocol tcp --port 8000 --cidr 0.0.0.0/0
```

### Stop EC2 (Save Cost)
```bash
aws ec2 stop-instances --instance-ids i-0cd39c0cf451a83cc
```

## 🏗️ Architecture

```
GitHub Actions (OIDC)
    ↓
AWS IAM Role (no credentials stored)
    ↓
EC2 Instance (SSM - no SSH)
    ↓
Run pytest → Generate Allure → Upload S3 → Serve port 8000
```

## 🔒 Security Features

- ✅ No SSH keys (uses SSM)
- ✅ No long-lived credentials (OIDC)
- ✅ Least privilege IAM roles
- ✅ No port 22 open
- ✅ All commands audited

## 💰 Cost

- **EC2 t3.medium**: ~$0.04/hour
- **S3**: ~$0.02/month (100 runs)
- **Recommendation**: Stop EC2 when not in use

## ✅ Setup Checklist

- [ ] AWS Account setup
- [ ] S3 bucket created
- [ ] IAM roles created (GitHub + EC2)
- [ ] EC2 instance launched
- [ ] Security group port 8000 open
- [ ] GitHub secret added (AWS_ROLE_ARN)
- [ ] Run workflow successfully
- [ ] Access report on port 8000

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Port 8000 blocked | Add security group rule |
| Tests not found | Check git clone in setup logs |
| EC2 stopped | Start: `aws ec2 start-instances` |
| Report empty | Check pytest output for errors |

## 📈 Next Steps

- [ ] Add more test cases
- [ ] Setup Elastic IP (fixed IP for EC2)
- [ ] Add Slack notifications
- [ ] Setup scheduled runs
- [ ] Add multiple test suites
- [ ] Implement test parallelization
