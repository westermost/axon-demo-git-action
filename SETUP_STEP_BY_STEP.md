# Setup Guide - Step by Step

## Prerequisites

- AWS Account với admin access
- AWS CLI installed và configured
- GitHub account

---

## STEP 1: Lấy thông tin cần thiết

```bash
# Lấy AWS Account ID
aws sts get-caller-identity --query Account --output text

# Lưu lại các thông tin:
# - AWS Account ID: ____________
# - GitHub Username: westermost
# - GitHub Repo: axon-demo-git-action
# - AWS Region: us-east-1 (hoặc region bạn chọn)
```

---

## STEP 2: Tạo S3 Bucket cho test results

```bash
# Tạo bucket với tên unique
BUCKET_NAME="playwright-test-results-$(date +%s)"
echo "Bucket name: $BUCKET_NAME"

# Tạo bucket
aws s3 mb s3://$BUCKET_NAME --region us-east-1

# Verify
aws s3 ls | grep playwright-test-results
```

**✓ Lưu lại bucket name:** `_______________________`

---

## STEP 3: Tạo OIDC Provider cho GitHub Actions

```bash
# Tạo OIDC provider (chỉ cần làm 1 lần cho AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Verify
aws iam list-open-id-connect-providers
```

**Expected output:** Thấy provider với URL `token.actions.githubusercontent.com`

---

## STEP 4: Tạo IAM Role cho GitHub Actions

### 4.1. Tạo Trust Policy

```bash
# Thay YOUR_ACCOUNT_ID, YOUR_GITHUB_ORG, YOUR_REPO
cat > github-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO:*"
      }
    }
  }]
}
EOF

# Sửa file với thông tin thực tế
nano github-trust-policy.json
# Hoặc dùng sed:
sed -i 's/YOUR_ACCOUNT_ID/123456789012/g' github-trust-policy.json
sed -i 's/YOUR_GITHUB_ORG/westermost/g' github-trust-policy.json
sed -i 's/YOUR_REPO/axon-demo-git-action/g' github-trust-policy.json

# Xem file để verify
cat github-trust-policy.json
```

### 4.2. Tạo Role

```bash
# Tạo role
aws iam create-role \
  --role-name GitHubActionsPlaywrightRole \
  --assume-role-policy-document file://github-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name GitHubActionsPlaywrightRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-role-policy \
  --role-name GitHubActionsPlaywrightRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess

aws iam attach-role-policy \
  --role-name GitHubActionsPlaywrightRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Verify
aws iam get-role --role-name GitHubActionsPlaywrightRole
```

**✓ Lưu lại Role ARN:** `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsPlaywrightRole`

---

## STEP 5: Tạo IAM Role cho EC2 Instance

### 5.1. Tạo EC2 Trust Policy

```bash
cat > ec2-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
EOF
```

### 5.2. Tạo Role và Instance Profile

```bash
# Tạo role
aws iam create-role \
  --role-name SSMPlaywrightInstanceRole \
  --assume-role-policy-document file://ec2-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name SSMPlaywrightInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam attach-role-policy \
  --role-name SSMPlaywrightInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Tạo instance profile
aws iam create-instance-profile \
  --instance-profile-name SSMPlaywrightInstanceProfile

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name SSMPlaywrightInstanceProfile \
  --role-name SSMPlaywrightInstanceRole

# Verify
aws iam get-instance-profile --instance-profile-name SSMPlaywrightInstanceProfile
```

**⏳ Đợi 10 giây** để IAM propagate:
```bash
sleep 10
```

---

## STEP 6: Launch EC2 Instance

```bash
# Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --instance-type t3.medium \
  --iam-instance-profile Name=SSMPlaywrightInstanceProfile \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Playwright-Test-Runner}]' \
  --region us-east-1 \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# Đợi instance running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Verify
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name,InstanceType]' \
  --output table
```

**✓ Lưu lại Instance ID:** `_______________________`

---

## STEP 7: Verify SSM Agent

```bash
# Đợi SSM agent ready (có thể mất 1-2 phút)
echo "Waiting for SSM agent..."
sleep 60

# Check SSM status
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query 'InstanceInformationList[0].[InstanceId,PingStatus,PlatformName]' \
  --output table
```

**Expected:** PingStatus = `Online`

Nếu chưa Online, đợi thêm và check lại:
```bash
sleep 30
# Chạy lại command trên
```

---

## STEP 8: Test SSM Connection

```bash
# Test command đơn giản
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["echo Hello from SSM", "uname -a", "whoami"]' \
  --query 'Command.CommandId' \
  --output text

# Lưu Command ID và check kết quả sau 10 giây
COMMAND_ID="<command-id-from-above>"

sleep 10

aws ssm get-command-invocation \
  --command-id $COMMAND_ID \
  --instance-id $INSTANCE_ID \
  --query 'StandardOutputContent' \
  --output text
```

**Expected:** Thấy output "Hello from SSM" và thông tin system

---

## STEP 9: Add GitHub Secret

### 9.1. Vào GitHub Repository Settings

1. Mở browser: `https://github.com/westermost/axon-demo-git-action`
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 9.2. Add Secret

- **Name:** `AWS_ROLE_ARN`
- **Value:** `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsPlaywrightRole`
  
  (Thay YOUR_ACCOUNT_ID bằng account ID thực tế)

5. Click **Add secret**

---

## STEP 10: Run GitHub Actions Workflow

### 10.1. Vào Actions Tab

1. Mở: `https://github.com/westermost/axon-demo-git-action/actions`
2. Click workflow **"Playwright Tests on AWS EC2 (SSM)"**
3. Click **Run workflow** (button màu xanh)

### 10.2. Nhập Parameters

- **instance_id:** `<your-instance-id-from-step-6>`
- **s3_bucket:** `<your-bucket-name-from-step-2>`

4. Click **Run workflow**

### 10.3. Monitor Workflow

- Click vào workflow run đang chạy
- Xem logs real-time
- Đợi workflow hoàn thành (~5-10 phút)

---

## STEP 11: Download Test Results

Sau khi workflow hoàn thành:

1. Scroll xuống **Artifacts** section
2. Download:
   - `playwright-report-ec2` - Playwright HTML report
   - `allure-report-ec2` - Allure report

3. Extract và mở `index.html` trong browser

---

## STEP 12: Verify Results in S3

```bash
# List files in S3
aws s3 ls s3://$BUCKET_NAME/ --recursive

# Download results
aws s3 cp s3://$BUCKET_NAME/ ./s3-results/ --recursive
```

---

## STEP 13: Cleanup (Sau khi test xong)

```bash
# Stop instance (để tiết kiệm chi phí)
aws ec2 stop-instances --instance-ids $INSTANCE_ID

# Hoặc terminate (xóa hoàn toàn)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Xóa S3 bucket
aws s3 rb s3://$BUCKET_NAME --force

# (Optional) Xóa IAM roles nếu không dùng nữa
aws iam remove-role-from-instance-profile \
  --instance-profile-name SSMPlaywrightInstanceProfile \
  --role-name SSMPlaywrightInstanceRole

aws iam delete-instance-profile \
  --instance-profile-name SSMPlaywrightInstanceProfile

aws iam detach-role-policy \
  --role-name SSMPlaywrightInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam detach-role-policy \
  --role-name SSMPlaywrightInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam delete-role --role-name SSMPlaywrightInstanceRole

# Tương tự cho GitHubActionsPlaywrightRole
```

---

## Troubleshooting

### Issue 1: SSM Agent không Online

**Check:**
```bash
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID
```

**Fix:**
- Đợi thêm 1-2 phút
- Verify instance profile attached đúng
- Reboot instance: `aws ec2 reboot-instances --instance-ids $INSTANCE_ID`

### Issue 2: GitHub Actions không assume role được

**Check:**
- Verify OIDC provider exists
- Check trust policy có đúng repo name
- Verify secret `AWS_ROLE_ARN` đã add

**Fix:**
```bash
# Re-check trust policy
aws iam get-role --role-name GitHubActionsPlaywrightRole \
  --query 'Role.AssumeRolePolicyDocument'
```

### Issue 3: Tests fail trên EC2

**Check logs trong workflow:**
- Node.js installed?
- npm dependencies installed?
- Playwright browsers installed?

**Manual test:**
```bash
# SSH vào EC2 qua SSM
aws ssm start-session --target $INSTANCE_ID

# Test commands
node --version
npm --version
```

### Issue 4: S3 upload fails

**Check:**
```bash
# Verify EC2 role có S3 permissions
aws iam list-attached-role-policies --role-name SSMPlaywrightInstanceRole

# Test S3 access từ EC2
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["aws s3 ls"]'
```

---

## Summary Checklist

- [ ] S3 bucket created
- [ ] OIDC provider created
- [ ] GitHub Actions IAM role created
- [ ] EC2 IAM role created
- [ ] EC2 instance launched
- [ ] SSM agent online
- [ ] GitHub secret added
- [ ] Workflow runs successfully
- [ ] Test results downloaded

---

## Quick Reference

```bash
# Your configuration (fill in):
AWS_ACCOUNT_ID="____________"
AWS_REGION="us-east-1"
INSTANCE_ID="____________"
BUCKET_NAME="____________"
GITHUB_ORG="westermost"
GITHUB_REPO="axon-demo-git-action"
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsPlaywrightRole"
```

Save this to `.env` file for easy reference!
