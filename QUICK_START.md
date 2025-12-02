# Quick Start Guide

## 🚀 5-Minute Setup

### 1. Create S3 Bucket
```bash
BUCKET_NAME="playwright-test-results-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME
```

### 2. Create OIDC Provider
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 3. Create GitHub Actions Role
```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create trust policy
cat > trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
      "StringLike": {"token.actions.githubusercontent.com:sub": "repo:westermost/axon-demo-git-action:*"}
    }
  }]
}
EOF

# Create role
aws iam create-role --role-name GitHubActionsPlaywrightRole --assume-role-policy-document file://trust.json
aws iam attach-role-policy --role-name GitHubActionsPlaywrightRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam attach-role-policy --role-name GitHubActionsPlaywrightRole --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess
aws iam attach-role-policy --role-name GitHubActionsPlaywrightRole --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### 4. Create EC2 Role
```bash
cat > ec2-trust.json << 'EOF'
{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "ec2.amazonaws.com"}, "Action": "sts:AssumeRole"}]}
EOF

aws iam create-role --role-name SSMPlaywrightInstanceRole --assume-role-policy-document file://ec2-trust.json
aws iam attach-role-policy --role-name SSMPlaywrightInstanceRole --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam attach-role-policy --role-name SSMPlaywrightInstanceRole --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam create-instance-profile --instance-profile-name SSMPlaywrightInstanceProfile
aws iam add-role-to-instance-profile --instance-profile-name SSMPlaywrightInstanceProfile --role-name SSMPlaywrightInstanceRole
sleep 10
```

### 5. Launch EC2
```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --instance-type t3.medium \
  --iam-instance-profile Name=SSMPlaywrightInstanceProfile \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Playwright-Test-Runner}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
```

### 6. Add GitHub Secret
1. Go to: https://github.com/westermost/axon-demo-git-action/settings/secrets/actions
2. Add secret:
   - Name: `AWS_ROLE_ARN`
   - Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsPlaywrightRole`

### 7. Run Workflow
1. Go to: https://github.com/westermost/axon-demo-git-action/actions
2. Select "Playwright Tests on AWS EC2 (SSM)"
3. Click "Run workflow"
4. Enter:
   - instance_id: `<from step 5>`
   - s3_bucket: `<from step 1>`

---

## 📝 Save Your Config

```bash
cat > .env << EOF
ACCOUNT_ID=$ACCOUNT_ID
INSTANCE_ID=$INSTANCE_ID
BUCKET_NAME=$BUCKET_NAME
ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/GitHubActionsPlaywrightRole
EOF
```

---

## 🧹 Cleanup

```bash
source .env
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws s3 rb s3://$BUCKET_NAME --force
```

---

## 📚 Full Documentation

- **Detailed Guide:** [SETUP_STEP_BY_STEP.md](./SETUP_STEP_BY_STEP.md)
- **Workflow Guide:** [WORKFLOW_GUIDE.md](./WORKFLOW_GUIDE.md)
- **README:** [README.md](./README.md)
