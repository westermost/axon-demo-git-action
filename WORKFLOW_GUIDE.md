# GitHub Actions Workflow Guide

## Available Workflows

### 1. Basic Workflow (test.yml)
Runs tests directly on GitHub Actions runners.

**Trigger**: Push to master/main, PR, or manual

**Features**:
- ✅ Runs on GitHub-hosted runners
- ✅ Fast setup and execution
- ✅ Automatic Allure report generation
- ✅ Artifacts uploaded for 30 days

**Usage**:
```bash
git push origin master
```

### 2. AWS EC2 Workflow (test-aws-ec2.yml)
Runs tests on AWS EC2 instance via SSM.

**Trigger**: Manual workflow dispatch

**Features**:
- ✅ Runs on dedicated EC2 instance
- ✅ No SSH required (uses SSM)
- ✅ Results uploaded to S3
- ✅ Auto start/stop EC2
- ✅ OIDC authentication (no credentials stored)

**Usage**:
1. Go to GitHub Actions tab
2. Select "Playwright Tests on AWS EC2 (SSM)"
3. Click "Run workflow"
4. Enter:
   - EC2 Instance ID (e.g., i-0123456789abcdef)
   - S3 Bucket name (e.g., corev2-test-results)

## Setup Requirements

### For Basic Workflow
No setup required - works out of the box!

### For AWS EC2 Workflow

#### 1. Create IAM OIDC Provider
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### 2. Create IAM Role for GitHub Actions
```bash
# Replace with your values
GITHUB_ORG="westermost"
GITHUB_REPO="axon-demo-git-action"
AWS_ACCOUNT_ID="123456789012"

# Create trust policy
cat > github-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
      }
    }
  }]
}
EOF

# Create role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://github-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

#### 3. Create EC2 Instance with SSM
```bash
# Launch instance with SSM role
aws ec2 run-instances \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --instance-type t3.medium \
  --iam-instance-profile Name=SSMInstanceProfile \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Playwright-Test-Runner}]'
```

#### 4. Create S3 Bucket
```bash
aws s3 mb s3://corev2-test-results-$(date +%s)
```

#### 5. Add GitHub Secret
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add new secret:
   - Name: `AWS_ROLE_ARN`
   - Value: `arn:aws:iam::123456789012:role/GitHubActionsRole`

## Viewing Reports

### Playwright HTML Report
1. Go to Actions → Select workflow run
2. Download "playwright-report" artifact
3. Extract and open `index.html`

### Allure Report
1. Download "allure-report" artifact
2. Extract and open `index.html`

Or use Allure server:
```bash
npm install -g allure-commandline
allure open allure-report
```

## Troubleshooting

### SSM Agent not ready
- Wait longer (increase sleep time in workflow)
- Check EC2 has SSM role attached
- Verify SSM agent is running: `systemctl status amazon-ssm-agent`

### Tests fail on EC2
- Check EC2 has enough resources (t3.medium minimum)
- Verify Node.js installed correctly
- Check S3 bucket permissions

### S3 upload fails
- Verify EC2 instance role has S3 write permissions
- Check S3 bucket exists and is accessible
- Verify bucket name in workflow input
