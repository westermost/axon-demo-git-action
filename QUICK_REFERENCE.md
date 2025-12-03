# Quick Reference

## Run Workflow

### Option 1: Automatic (Pull Request)
1. Create branch and add changes:
   ```bash
   git checkout -b add-new-test
   # Make changes
   git add .
   git commit -m "Add new test"
   git push origin add-new-test
   ```
2. Create PR on GitHub
3. Workflow runs automatically
4. View results in Actions tab

### Option 2: Manual
1. Go to: https://github.com/westermost/axon-demo-git-action/actions
2. Click: "Python Tests on AWS EC2 (SSM)"
3. Click: "Run workflow"
4. Tests run on EC2 instance `i-0cd39c0cf451a83cc`

## View Reports

### Option 1: EC2 Server (Fastest)
```
http://<EC2-PUBLIC-IP>:8000
```
**Note**: Server tự động restart mỗi lần workflow chạy để hiển thị report mới nhất. Nếu thấy report cũ, hard refresh (Ctrl+F5).

### Option 2: S3 Online
```
https://kiemtraxe.s3.ap-southeast-1.amazonaws.com/<YYYYMMDD-HHMMSS>/allure-report/index.html
```

### Option 3: Pytest HTML
```
https://kiemtraxe.s3.ap-southeast-1.amazonaws.com/<YYYYMMDD-HHMMSS>/report.html
```

## Common Commands

### Get EC2 Public IP
```bash
aws ec2 describe-instances \
  --instance-ids i-0cd39c0cf451a83cc \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

### Open Port 8000
```bash
# Get Security Group ID
SG_ID=$(aws ec2 describe-instances \
  --instance-ids i-0cd39c0cf451a83cc \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

# Add rule
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8000 \
  --cidr 0.0.0.0/0
```

### Stop EC2 (Save Cost)
```bash
aws ec2 stop-instances --instance-ids i-0cd39c0cf451a83cc
```

### Start EC2
```bash
aws ec2 start-instances --instance-ids i-0cd39c0cf451a83cc
```

### Check EC2 Status
```bash
aws ec2 describe-instances \
  --instance-ids i-0cd39c0cf451a83cc \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

### SSH via SSM (No PEM key)
```bash
aws ssm start-session --target i-0cd39c0cf451a83cc
```

### Restart Allure Server Manually
```bash
# Kill old server
aws ssm send-command \
  --instance-ids i-0cd39c0cf451a83cc \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["pkill -f \"python3 -m http.server 8000\""]'

# Start new server (replace RUN_ID with actual timestamp)
aws ssm send-command \
  --instance-ids i-0cd39c0cf451a83cc \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd /tmp/test-<RUN_ID>/allure-report && nohup python3 -m http.server 8000 &"]'
```

### List S3 Test Results
```bash
aws s3 ls s3://kiemtraxe/ --recursive
```

### Download Report from S3
```bash
aws s3 cp s3://kiemtraxe/<YYYYMMDD-HHMMSS>/allure-report.tar.gz .
tar -xzf allure-report.tar.gz
cd allure-report && python3 -m http.server 8000
```

## Workflow Steps

1. **Setup** (~2 min) - Install git, pip, Java, pytest, Allure
2. **Run Tests** (~30 sec) - Execute 3 tests, upload HTML
3. **Generate Allure** (~10 sec) - Create Allure report
4. **Upload S3** (~5 sec) - Upload HTML + zip
5. **Serve** (~1 sec) - Start HTTP server on port 8000

**Total**: ~3-4 minutes

## Troubleshooting

### Port 8000 blocked
→ Add security group rule (see above)

### EC2 stopped
→ Start EC2: `aws ec2 start-instances --instance-ids i-0cd39c0cf451a83cc`

### Tests not found
→ Check setup logs for git clone errors

### Report not loading
→ Check EC2 public IP changed (elastic IP recommended)

## Cost Estimate

- **EC2 t3.medium**: ~$0.04/hour (~$30/month if running 24/7)
- **S3 storage**: ~$0.023/GB/month (~$0.02/month for 100 test runs)
- **Data transfer**: Free tier 100GB/month

**Recommendation**: Stop EC2 when not in use → ~$1-2/month
