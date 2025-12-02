# Option 2: GitHub Actions + AWS SSM Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          GitHub Actions                              │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Workflow: CoreV2 Tests                                     │    │
│  │                                                              │    │
│  │  1. Trigger (push/PR/manual)                                │    │
│  │  2. Checkout code                                           │    │
│  │  3. Configure AWS credentials (OIDC)                        │    │
│  │  4. Start EC2 instance                                      │    │
│  │  5. Run tests via SSM                                       │    │
│  │  6. Download results from S3                                │    │
│  │  7. Generate Allure report                                  │    │
│  │  8. Stop EC2 instance                                       │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
└──────────────────┬───────────────────────────────────────────────────┘
                   │
                   │ ① OIDC Authentication
                   │ (No long-lived credentials)
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                                   │
│                                                                      │
│  ┌──────────────────────┐                                           │
│  │   IAM Role (OIDC)    │                                           │
│  │  GitHubActionsRole   │                                           │
│  │                      │                                           │
│  │  Permissions:        │                                           │
│  │  • EC2 Start/Stop    │                                           │
│  │  • SSM SendCommand   │                                           │
│  │  • S3 Read           │                                           │
│  └──────────┬───────────┘                                           │
│             │                                                        │
│             │ ② Assume Role                                         │
│             ▼                                                        │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │                    AWS Services                          │       │
│  │                                                           │       │
│  │  ┌──────────┐    ┌──────────┐    ┌──────────┐          │       │
│  │  │   EC2    │◄───│   SSM    │    │    S3    │          │       │
│  │  │  API     │    │ Session  │    │  Bucket  │          │       │
│  │  └────┬─────┘    │ Manager  │    └─────▲────┘          │       │
│  │       │          └─────┬────┘          │               │       │
│  │       │                │               │               │       │
│  │       │ ③ Start        │ ④ Execute     │ ⑤ Upload     │       │
│  │       │ Instance       │ Commands      │ Results       │       │
│  │       ▼                ▼               │               │       │
│  │  ┌─────────────────────────────────────┴──────┐        │       │
│  │  │         EC2 Instance (Test Runner)         │        │       │
│  │  │                                             │        │       │
│  │  │  • SSM Agent (no SSH needed)               │        │       │
│  │  │  • CoreV2 Test Framework                   │        │       │
│  │  │  • QEMU for testing                        │        │       │
│  │  │  • pytest + Allure                         │        │       │
│  │  │                                             │        │       │
│  │  │  Runs: pytest --alluredir=allure-results   │        │       │
│  │  └─────────────────────────────────────────────┘        │       │
│  └─────────────────────────────────────────────────────────┘       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                   │
                   │ ⑥ Download Results
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    GitHub Actions (continued)                        │
│                                                                      │
│  • Generate Allure HTML Report                                      │
│  • Publish to GitHub Pages / Artifacts                              │
│  • Comment PR with test results                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Flow Steps:

1. **OIDC Authentication**: GitHub Actions authenticates to AWS using OIDC (no stored secrets)
2. **Assume Role**: GitHub Actions assumes IAM role with minimal permissions
3. **Start Instance**: EC2 instance is started on-demand
4. **Execute Commands**: SSM sends test commands to EC2 (no SSH/PEM keys needed)
5. **Upload Results**: EC2 uploads test results and logs to S3
6. **Download Results**: GitHub Actions downloads artifacts from S3
7. **Generate Report**: Allure report is generated and published
8. **Stop Instance**: EC2 is stopped to save costs

## Security Benefits:

- ✅ No SSH keys or PEM files
- ✅ No long-lived AWS credentials
- ✅ No open port 22 on EC2
- ✅ All commands audited via SSM
- ✅ Minimal IAM permissions (least privilege)
