# Project Summary

## 📁 Documentation Files

| File | Purpose | When to Use |
|------|---------|-------------|
| **SETUP_CONSOLE.md** | Setup qua AWS Console (GUI) | 👉 KHUYẾN NGHỊ - Không cần CLI |
| **QUICK_START.md** | 5-minute setup commands | Bạn muốn setup nhanh, đã quen AWS CLI |
| **SETUP_STEP_BY_STEP.md** | Chi tiết từng bước CLI + troubleshooting | Prefer command line |
| **WORKFLOW_GUIDE.md** | Giải thích workflows | Hiểu cách workflows hoạt động |
| **README.md** | Project overview | Tổng quan project |

## 🎯 Workflows

### 1. Basic Workflow (test.yml)
- ✅ Chạy trên GitHub runners
- ✅ Không cần AWS setup
- ✅ Tự động chạy khi push code
- 📍 Use case: Development, quick testing

### 2. AWS EC2 Workflow (test-aws-ec2.yml)
- ✅ Chạy trên EC2 instance
- ✅ Dùng SSM (không SSH)
- ✅ Upload results lên S3
- ✅ Manual trigger
- 📍 Use case: Production testing, heavy workloads

## 🧪 Tests

- **demo.spec.ts**: 5 basic Playwright tests
- **allure-demo.spec.ts**: 5 tests với Allure annotations
- **Total**: 10 tests, 100% pass rate

## 🚀 Quick Commands

### Run tests locally
```bash
npm install
npx playwright install chromium
npm test
```

### Setup AWS (one-time)
```bash
./setup-aws.sh
# Or follow QUICK_START.md
```

### Cleanup AWS
```bash
aws ec2 terminate-instances --instance-ids <instance-id>
aws s3 rb s3://<bucket-name> --force
```

## 📊 Architecture

```
GitHub Actions (OIDC)
    ↓
AWS IAM Role
    ↓
EC2 Instance (SSM)
    ↓
Run Playwright Tests
    ↓
Upload to S3
    ↓
Download Results
    ↓
Generate Reports
```

## 🔗 Links

- **Repository**: https://github.com/westermost/axon-demo-git-action
- **Actions**: https://github.com/westermost/axon-demo-git-action/actions
- **Settings**: https://github.com/westermost/axon-demo-git-action/settings

## ✅ Setup Checklist

- [ ] Read QUICK_START.md or SETUP_STEP_BY_STEP.md
- [ ] Create S3 bucket
- [ ] Create IAM roles (GitHub + EC2)
- [ ] Launch EC2 instance
- [ ] Add GitHub secret (AWS_ROLE_ARN)
- [ ] Run workflow
- [ ] Download reports
- [ ] Cleanup resources

## 💡 Tips

1. **Start with basic workflow** (test.yml) - không cần setup gì
2. **Setup AWS** khi cần test trên EC2 thật
3. **Stop EC2** khi không dùng để tiết kiệm chi phí
4. **Check S3 costs** - xóa old results thường xuyên
5. **Use t3.medium** minimum cho Playwright + Chromium

## 🆘 Need Help?

1. Check **SETUP_STEP_BY_STEP.md** → Troubleshooting section
2. Check workflow logs trong GitHub Actions
3. Verify IAM roles và permissions
4. Test SSM connection manually

## 📈 Next Steps

- [ ] Add more test cases
- [ ] Setup GitHub Pages for Allure reports
- [ ] Add Slack/Email notifications
- [ ] Setup scheduled runs (cron)
- [ ] Add multiple browsers (Firefox, Safari)
- [ ] Implement test parallelization
