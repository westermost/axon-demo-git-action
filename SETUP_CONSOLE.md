# Setup Guide - AWS Console (No CLI Required)

Hướng dẫn setup qua giao diện AWS Console cho Python + pytest + Allure.

---

## STEP 1: Lấy AWS Account ID

1. Đăng nhập AWS Console: https://console.aws.amazon.com
2. Click vào **tên user** ở góc phải trên
3. Copy **Account ID** (12 chữ số)

**✓ Lưu lại:** `____________`

---

## STEP 2: Tạo S3 Bucket

1. Vào **S3** service: https://s3.console.aws.amazon.com
2. Click **Create bucket**
3. Nhập thông tin:
   - **Bucket name:** `test-results-<timestamp>` (ví dụ: test-results-20241203)
   - **AWS Region:** `Asia Pacific (Singapore) ap-southeast-1`
   - Để mặc định các settings khác
4. Click **Create bucket**

**✓ Lưu lại bucket name:** `____________`

---

## STEP 3: Tạo OIDC Provider cho GitHub

1. Vào **IAM** service: https://console.aws.amazon.com/iam
2. Click **Identity providers** (menu bên trái)
3. Click **Add provider**
4. Chọn **OpenID Connect**
5. Nhập thông tin:
   - **Provider URL:** `https://token.actions.githubusercontent.com`
   - Click **Get thumbprint**
   - **Audience:** `sts.amazonaws.com`
6. Click **Add provider**

---

## STEP 4: Tạo IAM Role cho GitHub Actions

### 4.1. Tạo Role

1. Vào **IAM** → **Roles**
2. Click **Create role**
3. Chọn **Custom trust policy**
4. Paste policy sau (thay `YOUR_ACCOUNT_ID`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
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
          "token.actions.githubusercontent.com:sub": "repo:westermost/axon-demo-git-action:*"
        }
      }
    }
  ]
}
```

5. Click **Next**

### 4.2. Attach Permissions

6. Tìm và chọn các policies:
   - ☑️ `AmazonEC2FullAccess`
   - ☑️ `AmazonSSMFullAccess`
   - ☑️ `AmazonS3FullAccess`
7. Click **Next**

### 4.3. Đặt tên Role

8. **Role name:** `GitHubActionsRole`
9. **Description:** `Role for GitHub Actions to run tests on EC2`
10. Click **Create role**

**✓ Lưu lại Role ARN:** `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole`

---

## STEP 5: Tạo IAM Role cho EC2 Instance

### 5.1. Tạo Role

1. Vào **IAM** → **Roles**
2. Click **Create role**
3. Chọn **AWS service**
4. Chọn **EC2**
5. Click **Next**

### 5.2. Attach Permissions

6. Tìm và chọn:
   - ☑️ `AmazonSSMManagedInstanceCore`
   - ☑️ `AmazonS3FullAccess`
7. Click **Next**

### 5.3. Đặt tên Role

8. **Role name:** `SSMInstanceRole`
9. **Description:** `Role for EC2 to use SSM and upload to S3`
10. Click **Create role**

---

## STEP 6: Launch EC2 Instance

1. Vào **EC2** service: https://console.aws.amazon.com/ec2
2. Click **Launch instance**

### 6.1. Name and AMI

3. **Name:** `Test-Runner`
4. **AMI:** Chọn **Amazon Linux 2023 AMI** (free tier eligible)

### 6.2. Instance Type

5. **Instance type:** `t3.medium`

### 6.3. Key Pair

6. **Key pair:** Chọn **Proceed without a key pair** (không cần vì dùng SSM)

### 6.4. Network Settings

7. **Auto-assign public IP:** Enable
8. **Firewall (security groups):** Create new security group
   - Allow SSH (port 22) - Optional
   - **Add rule:** Custom TCP, Port 8000, Source: 0.0.0.0/0 (for Allure report)

### 6.5. IAM Instance Profile

9. Click **Advanced details** (mở rộng)
10. **IAM instance profile:** Chọn `SSMInstanceRole`

### 6.6. Launch

11. Click **Launch instance**
12. Đợi instance chuyển sang **Running** (~1-2 phút)
13. Click vào instance → Copy **Public IPv4 address**

**✓ Lưu lại:**
- Instance ID: `____________`
- Public IP: `____________`

---

## STEP 7: Verify SSM Agent

1. Vào **Systems Manager** service: https://console.aws.amazon.com/systems-manager
2. Click **Fleet Manager** (menu bên trái)
3. Đợi 1-2 phút để SSM agent kết nối
4. Tìm instance của bạn trong danh sách
5. **Status** phải là **Online**

Nếu chưa thấy:
- Đợi thêm 2-3 phút
- Refresh trang
- Verify IAM role đã attach đúng

---

## STEP 8: Test SSM Connection

1. Vẫn trong **Systems Manager**
2. Click **Session Manager** (menu bên trái)
3. Click **Start session**
4. Chọn instance của bạn
5. Click **Start session**
6. Terminal sẽ mở ra
7. Gõ test command:
   ```bash
   echo "Hello from SSM"
   python3 --version
   ```
8. Nếu thấy output → SSM hoạt động ✓
9. Click **Terminate** để đóng

---

## STEP 8.5: Setup SSH Deploy Key (For Private Repos)

**Lưu ý:** Bỏ qua bước này nếu repo là **public**.

### 8.5.1. Generate SSH Key trên EC2

1. Vào **Systems Manager** → **Session Manager**
2. Click **Start session** → Chọn instance
3. Chạy lệnh tạo SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "ec2-deploy-key" -f ~/.ssh/github_deploy_key -N ""
   ```
4. Xem public key:
   ```bash
   cat ~/.ssh/github_deploy_key.pub
   ```
5. **Copy toàn bộ output** (bắt đầu với `ssh-ed25519...`)

### 8.5.2. Add Deploy Key vào GitHub

6. Mở GitHub repo: https://github.com/westermost/axon-demo-git-action
7. Click **Settings** → **Deploy keys** (menu bên trái)
8. Click **Add deploy key**
9. Nhập:
   - **Title:** `EC2 Test Runner`
   - **Key:** Paste public key từ bước 5
   - ☑️ **Allow write access** (nếu cần push results)
10. Click **Add key**

### 8.5.3. Configure SSH trên EC2

11. Quay lại SSM Session, tạo SSH config:
    ```bash
    cat > ~/.ssh/config << 'EOF'
    Host github.com
      HostName github.com
      User git
      IdentityFile ~/.ssh/github_deploy_key
      StrictHostKeyChecking no
    EOF
    chmod 600 ~/.ssh/config
    ```

12. Test kết nối:
    ```bash
    ssh -T git@github.com
    ```
    
    Kết quả mong đợi: `Hi westermost/axon-demo-git-action! You've successfully authenticated...`

13. Click **Terminate** để đóng session

**✓ Deploy key đã sẵn sàng!** Workflow sẽ clone repo bằng SSH URL.

---

## STEP 9: Add GitHub Secret

### 9.1. Vào GitHub Repository

1. Mở: https://github.com/westermost/axon-demo-git-action
2. Click tab **Settings**
3. Click **Secrets and variables** → **Actions**

### 9.2. Add Secret

4. Click **New repository secret**
5. Nhập:
   - **Name:** `AWS_ROLE_ARN`
   - **Secret:** `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole`
   
   (Thay YOUR_ACCOUNT_ID bằng account ID từ Step 1)

6. Click **Add secret**

---

## STEP 10: Run GitHub Actions Workflow

### 10.1. Vào Actions Tab

1. Mở: https://github.com/westermost/axon-demo-git-action/actions
2. Click workflow **"Python Tests on AWS EC2 (SSM)"**
3. Click nút **Run workflow** (màu xanh)

### 10.2. Nhập Parameters

4. Form sẽ hiện ra:
   - **instance_id:** Paste Instance ID từ STEP 6
   - **s3_bucket:** Paste Bucket name từ STEP 2

5. Click **Run workflow**

### 10.3. Monitor Workflow

6. Workflow sẽ xuất hiện trong danh sách
7. Click vào để xem chi tiết
8. Xem logs real-time
9. Đợi hoàn thành (~3-4 phút)

**Workflow steps:**
- ✓ Setup environment (~2 min)
- ✓ Run tests (~30 sec)
- ✓ Generate Allure report (~10 sec)
- ✓ Upload to S3 (~5 sec)
- ✓ Serve on port 8000 (~1 sec)

---

## STEP 11: View Test Reports

Sau khi workflow hoàn thành, có 3 cách xem reports:

### Option 1: EC2 HTTP Server (Fastest) ⭐

```
http://<PUBLIC_IP>:8000
```

Mở URL này trong browser để xem Allure report trực tiếp!

### Option 2: S3 Online

```
https://<bucket>.s3.ap-southeast-1.amazonaws.com/<run-id>/allure-report/index.html
```

### Option 3: Pytest HTML Report

```
https://<bucket>.s3.ap-southeast-1.amazonaws.com/<run-id>/report.html
```

---

## STEP 12: Stop EC2 (Save Cost)

EC2 sẽ chạy liên tục. Để tiết kiệm chi phí:

1. Vào **EC2** console
2. Chọn instance của bạn
3. Click **Instance state** → **Stop instance**
4. Confirm

**Lưu ý:** Khi stop, Public IP sẽ thay đổi. Nên dùng Elastic IP nếu muốn IP cố định.

---

## Cleanup (Optional)

### Terminate EC2

1. Chọn instance
2. Click **Instance state** → **Terminate instance**
3. Confirm

### Delete S3 Bucket

1. Vào **S3** console
2. Chọn bucket
3. Click **Empty** → Confirm
4. Click **Delete** → Nhập tên bucket → Confirm

### Delete IAM Roles

1. Vào **IAM** → **Roles**
2. Tìm `SSMInstanceRole` và `GitHubActionsRole`
3. Delete từng role

---

## Troubleshooting

### Issue 1: SSM Agent không Online

**Giải pháp:**
1. Đợi thêm 2-3 phút
2. Verify IAM role:
   - EC2 → chọn instance → Tab **Security** → xem **IAM Role**
   - Phải là `SSMInstanceRole`
3. Reboot instance:
   - Instance state → Reboot instance

### Issue 2: Port 8000 không access được

**Giải pháp:**
1. Check Security Group:
   - EC2 → chọn instance → Tab **Security**
   - Click vào Security Group
   - Tab **Inbound rules**
   - Phải có rule: TCP port 8000, Source 0.0.0.0/0
2. Nếu chưa có, click **Edit inbound rules** → Add rule

### Issue 3: GitHub Actions không assume role được

**Giải pháp:**
1. Verify OIDC provider:
   - IAM → Identity providers
   - Phải thấy `token.actions.githubusercontent.com`
2. Check trust policy:
   - IAM → Roles → GitHubActionsRole → Trust relationships
   - Verify repo name đúng: `westermost/axon-demo-git-action`
3. Check GitHub secret:
   - Verify `AWS_ROLE_ARN` có giá trị đúng

### Issue 4: Tests không chạy

**Giải pháp:**
1. Xem setup logs trong workflow
2. Check git clone có thành công không
3. Verify EC2 có internet access

### Issue 5: Allure report trống

**Giải pháp:**
1. Tests có thể đã fail
2. Check pytest output trong workflow logs
3. Verify allure-pytest đã được install

---

## Summary Checklist

- [ ] Lấy AWS Account ID
- [ ] Tạo S3 bucket (Singapore region)
- [ ] Tạo OIDC provider
- [ ] Tạo GitHub Actions IAM role
- [ ] Tạo EC2 IAM role
- [ ] Launch EC2 instance (với port 8000 open)
- [ ] Verify SSM agent online
- [ ] Test SSM connection
- [ ] Setup SSH Deploy Key (nếu private repo)
- [ ] Add GitHub secret
- [ ] Run workflow
- [ ] View report trên http://<IP>:8000
- [ ] Stop EC2 khi không dùng

---

## Quick Reference

**Thông tin cần lưu:**

```
AWS Account ID: ____________
S3 Bucket: ____________
EC2 Instance ID: ____________
EC2 Public IP: ____________
GitHub Actions Role ARN: arn:aws:iam::____________:role/GitHubActionsRole
```

**Report URL:** `http://<PUBLIC_IP>:8000`

**Links quan trọng:**

- AWS Console: https://console.aws.amazon.com
- GitHub Repo: https://github.com/westermost/axon-demo-git-action
- GitHub Actions: https://github.com/westermost/axon-demo-git-action/actions

---

## Cost Estimate

**Ước tính chi phí (Singapore region):**

- EC2 t3.medium: ~$0.05/hour (~$36/month nếu chạy 24/7)
- S3 storage: ~$0.025/GB/month (~$0.03/month cho 100 test runs)
- Data transfer: Free tier 100GB/month

**Khuyến nghị:** Stop EC2 khi không dùng → ~$1-2/month
