#!/bin/bash
set -e

echo "=== AWS Setup for GitHub Actions + EC2 Demo ==="
echo ""

# Get inputs
read -p "Enter your GitHub username/org: " GITHUB_ORG
read -p "Enter your GitHub repository name: " GITHUB_REPO
read -p "Enter AWS region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TIMESTAMP=$(date +%s)
BUCKET_NAME="playwright-test-results-${TIMESTAMP}"

echo ""
echo "Configuration:"
echo "  GitHub: ${GITHUB_ORG}/${GITHUB_REPO}"
echo "  AWS Account: ${AWS_ACCOUNT_ID}"
echo "  AWS Region: ${AWS_REGION}"
echo "  S3 Bucket: ${BUCKET_NAME}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Create S3 bucket
echo "[1/5] Creating S3 bucket..."
aws s3 mb s3://${BUCKET_NAME} --region ${AWS_REGION}

# Create OIDC provider
echo "[2/5] Creating OIDC provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>/dev/null || echo "OIDC provider already exists"

# Create GitHub Actions role
echo "[3/5] Creating IAM role for GitHub Actions..."
cat > /tmp/github-trust-policy.json << EOF
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

aws iam create-role \
  --role-name GitHubActionsPlaywrightRole \
  --assume-role-policy-document file:///tmp/github-trust-policy.json 2>/dev/null || \
  aws iam update-assume-role-policy \
    --role-name GitHubActionsPlaywrightRole \
    --policy-document file:///tmp/github-trust-policy.json

aws iam attach-role-policy \
  --role-name GitHubActionsPlaywrightRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess 2>/dev/null || true

aws iam attach-role-policy \
  --role-name GitHubActionsPlaywrightRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess 2>/dev/null || true

aws iam attach-role-policy \
  --role-name GitHubActionsPlaywrightRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || true

# Create EC2 role
echo "[4/5] Creating IAM role for EC2..."
cat > /tmp/ec2-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name SSMPlaywrightInstanceRole \
  --assume-role-policy-document file:///tmp/ec2-trust-policy.json 2>/dev/null || true

aws iam attach-role-policy \
  --role-name SSMPlaywrightInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore 2>/dev/null || true

aws iam attach-role-policy \
  --role-name SSMPlaywrightInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || true

aws iam create-instance-profile \
  --instance-profile-name SSMPlaywrightInstanceProfile 2>/dev/null || true

aws iam add-role-to-instance-profile \
  --instance-profile-name SSMPlaywrightInstanceProfile \
  --role-name SSMPlaywrightInstanceRole 2>/dev/null || true

sleep 10

# Launch EC2
echo "[5/5] Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --instance-type t3.medium \
  --iam-instance-profile Name=SSMPlaywrightInstanceProfile \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Playwright-Test-Runner}]' \
  --region ${AWS_REGION} \
  --query 'Instances[0].InstanceId' \
  --output text)

echo ""
echo "✓ Setup completed!"
echo ""
echo "=== Configuration ==="
echo "EC2 Instance ID: ${INSTANCE_ID}"
echo "S3 Bucket: ${BUCKET_NAME}"
echo "GitHub Actions Role ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsPlaywrightRole"
echo ""
echo "=== Next Steps ==="
echo "1. Add GitHub Secret:"
echo "   - Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/secrets/actions"
echo "   - Name: AWS_ROLE_ARN"
echo "   - Value: arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsPlaywrightRole"
echo ""
echo "2. Run workflow:"
echo "   - Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/actions"
echo "   - Select 'Playwright Tests on AWS EC2 (SSM)'"
echo "   - Click 'Run workflow'"
echo "   - Enter Instance ID: ${INSTANCE_ID}"
echo "   - Enter S3 Bucket: ${BUCKET_NAME}"
echo ""
echo "3. Cleanup when done:"
echo "   aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}"
echo "   aws s3 rb s3://${BUCKET_NAME} --force"
echo ""

# Save config
cat > .aws-config << EOF
INSTANCE_ID=${INSTANCE_ID}
S3_BUCKET=${BUCKET_NAME}
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
GITHUB_ORG=${GITHUB_ORG}
GITHUB_REPO=${GITHUB_REPO}
ROLE_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsPlaywrightRole
EOF

echo "Configuration saved to .aws-config"
