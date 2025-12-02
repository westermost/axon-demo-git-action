# Setup Guide - AWS Console (No CLI Required)

Hướng dẫn setup qua giao diện AWS Console, không cần dùng command line.

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
   - **Bucket name:** `playwright-test-results-<timestamp>` (ví dụ: playwright-test-results-20241202)
   - **AWS Region:** `us-east-1` (hoặc region bạn chọn)
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
4. Paste policy sau (thay `YOUR_ACCOUNT_ID`, `YOUR_GITHUB_ORG`, `YOUR_REPO`):

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

**Ví dụ:**
- YOUR_ACCOUNT_ID: `123456789012`
- YOUR_GITHUB_ORG: `westermost`
- YOUR_REPO: `axon-demo-git-action`

5. Click **Next**

### 4.2. Attach Permissions

6. Tìm và chọn các policies sau:
   - ☑️ `AmazonEC2FullAccess`
   - ☑️ `AmazonSSMFullAccess`
   - ☑️ `AmazonS3FullAccess`

7. Click **Next**

### 4.3. Đặt tên Role

8. **Role name:** `GitHubActionsPlaywrightRole`
9. **Description:** `Role for GitHub Actions to run Playwright tests on EC2`
10. Click **Create role**

**✓ Lưu lại Role ARN:** `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsPlaywrightRole`

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

8. **Role name:** `SSMPlaywrightInstanceRole`
9. **Description:** `Role for EC2 instance to use SSM and upload to S3`
10. Click **Create role**

---

## STEP 6: Launch EC2 Instance

1. Vào **EC2** service: https://console.aws.amazon.com/ec2
2. Click **Launch instance**

### 6.1. Name and AMI

3. **Name:** `Playwright-Test-Runner`
4. **AMI:** Chọn **Amazon Linux 2023 AMI** (free tier eligible)

### 6.2. Instance Type

5. **Instance type:** `t3.medium` (hoặc `t3.small` để test)

### 6.3. Key Pair

6. **Key pair:** Chọn **Proceed without a key pair** (không cần vì dùng SSM)

### 6.4. Network Settings

7. Để mặc định (VPC default, subnet default)
8. **Auto-assign public IP:** Enable

### 6.5. IAM Instance Profile

9. Click **Advanced details** (mở rộng)
10. **IAM instance profile:** Chọn `SSMPlaywrightInstanceRole`

### 6.6. Launch

11. Click **Launch instance**
12. Đợi instance chuyển sang trạng thái **Running** (~1-2 phút)

**✓ Lưu lại Instance ID:** `i-xxxxxxxxxxxxxxxxx`

---

## STEP 7: Verify SSM Agent

1. Vào **Systems Manager** service: https://console.aws.amazon.com/systems-manager
2. Click **Fleet Manager** (menu bên trái)
3. Đợi 1-2 phút để SSM agent kết nối
4. Tìm instance của bạn trong danh sách
5. **Status** phải là **Online**

Nếu chưa thấy instance:
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
6. Một terminal sẽ mở ra
7. Gõ lệnh test:
   ```bash
   echo "Hello from SSM"
   whoami
   ```
8. Nếu thấy output → SSM hoạt động ✓
9. Click **Terminate** để đóng session

---

## STEP 9: Add GitHub Secret

### 9.1. Vào GitHub Repository

1. Mở: https://github.com/westermost/axon-demo-git-action
2. Click tab **Settings**
3. Click **Secrets and variables** → **Actions** (menu bên trái)

### 9.2. Add Secret

4. Click **New repository secret**
5. Nhập:
   - **Name:** `AWS_ROLE_ARN`
   - **Secret:** `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsPlaywrightRole`
   
   (Thay YOUR_ACCOUNT_ID bằng account ID thực tế từ Step 1)

6. Click **Add secret**

---

## STEP 10: Run GitHub Actions Workflow

### 10.1. Vào Actions Tab

1. Mở: https://github.com/westermost/axon-demo-git-action/actions
2. Click workflow **"Playwright Tests on AWS EC2 (SSM)"** (bên trái)
3. Click nút **Run workflow** (màu xanh, góc phải)

### 10.2. Nhập Parameters

4. Một form sẽ hiện ra:
   - **instance_id:** Paste Instance ID từ Step 6
   - **s3_bucket:** Paste Bucket name từ Step 2

5. Click **Run workflow**

### 10.3. Monitor Workflow

6. Workflow sẽ xuất hiện trong danh sách
7. Click vào workflow run để xem chi tiết
8. Xem logs real-time của từng step
9. Đợi workflow hoàn thành (~5-10 phút)

**Các step workflow sẽ chạy:**
- ✓ Start EC2 instance
- ✓ Wait for SSM agent
- ✓ Setup Node.js on EC2
- ✓ Run Playwright tests
- ✓ Upload results to S3
- ✓ Download results
- ✓ Generate reports
- ✓ Stop EC2 instance

---

## STEP 11: Download Test Results

Sau khi workflow hoàn thành:

1. Scroll xuống cuối trang workflow
2. Tìm section **Artifacts**
3. Download các files:
   - **playwright-report-ec2** - Playwright HTML report
   - **allure-report-ec2** - Allure report

4. Extract file zip
5. Mở `index.html` trong browser để xem report

---

## STEP 12: Verify Results in S3

1. Vào **S3** console: https://s3.console.aws.amazon.com
2. Click vào bucket của bạn
3. Sẽ thấy folder với timestamp (ví dụ: `20241202-143000/`)
4. Bên trong có:
   - `playwright-report/` - HTML reports
   - `allure-results/` - JSON results
   - `results.tar.gz` - Compressed archive

---

## STEP 13: Cleanup Resources

### 13.1. Stop EC2 Instance (tiết kiệm chi phí)

1. Vào **EC2** console
2. Chọn instance của bạn
3. Click **Instance state** → **Stop instance**

### 13.2. Terminate EC2 (xóa hoàn toàn)

1. Chọn instance
2. Click **Instance state** → **Terminate instance**
3. Confirm

### 13.3. Delete S3 Bucket

1. Vào **S3** console
2. Chọn bucket của bạn
3. Click **Empty** (xóa tất cả files)
4. Confirm
5. Click **Delete** (xóa bucket)
6. Nhập tên bucket để confirm

### 13.4. (Optional) Delete IAM Roles

Nếu không dùng nữa:

1. Vào **IAM** → **Roles**
2. Tìm `SSMPlaywrightInstanceRole`
3. Click vào role
4. Click **Delete**
5. Confirm
6. Lặp lại cho `GitHubActionsPlaywrightRole`

---

## Troubleshooting

### Issue 1: SSM Agent không Online

**Triệu chứng:** Không thấy instance trong Fleet Manager

**Giải pháp:**
1. Đợi thêm 2-3 phút
2. Verify IAM role đã attach:
   - Vào EC2 → chọn instance
   - Tab **Security** → xem **IAM Role**
   - Phải là `SSMPlaywrightInstanceRole`
3. Reboot instance:
   - Instance state → Reboot instance

### Issue 2: GitHub Actions không assume role được

**Triệu chứng:** Workflow fail ở step "Configure AWS credentials"

**Giải pháp:**
1. Verify OIDC provider đã tạo:
   - IAM → Identity providers
   - Phải thấy `token.actions.githubusercontent.com`
2. Check trust policy của role:
   - IAM → Roles → GitHubActionsPlaywrightRole
   - Tab **Trust relationships**
   - Verify repo name đúng
3. Check GitHub secret:
   - GitHub repo → Settings → Secrets
   - Verify `AWS_ROLE_ARN` có giá trị đúng

### Issue 3: Tests fail trên EC2

**Triệu chứng:** Workflow chạy nhưng tests fail

**Giải pháp:**
1. Xem logs trong workflow để biết lỗi cụ thể
2. Check EC2 instance type:
   - Minimum: t3.small
   - Recommended: t3.medium
3. Test manual qua Session Manager:
   - Systems Manager → Session Manager
   - Start session vào instance
   - Chạy commands thủ công

### Issue 4: S3 upload fails

**Triệu chứng:** Tests chạy OK nhưng không upload được S3

**Giải pháp:**
1. Verify EC2 role có S3 permissions:
   - IAM → Roles → SSMPlaywrightInstanceRole
   - Tab **Permissions**
   - Phải có `AmazonS3FullAccess`
2. Check bucket name đúng trong workflow input
3. Verify bucket tồn tại:
   - S3 console → tìm bucket

### Issue 5: Workflow timeout

**Triệu chứng:** Workflow chạy quá lâu và timeout

**Giải pháp:**
1. Tăng instance type lên t3.medium
2. Check network connectivity của EC2
3. Verify EC2 có internet access (cần download packages)

---

## Summary Checklist

- [ ] Lấy AWS Account ID
- [ ] Tạo S3 bucket
- [ ] Tạo OIDC provider
- [ ] Tạo GitHub Actions IAM role
- [ ] Tạo EC2 IAM role
- [ ] Launch EC2 instance
- [ ] Verify SSM agent online
- [ ] Test SSM connection
- [ ] Add GitHub secret
- [ ] Run workflow
- [ ] Download reports
- [ ] Cleanup resources

---

## Quick Reference

**Thông tin cần lưu:**

```
AWS Account ID: ____________
S3 Bucket: ____________
EC2 Instance ID: ____________
GitHub Actions Role ARN: arn:aws:iam::____________:role/GitHubActionsPlaywrightRole
```

**Links quan trọng:**

- AWS Console: https://console.aws.amazon.com
- GitHub Repo: https://github.com/westermost/axon-demo-git-action
- GitHub Actions: https://github.com/westermost/axon-demo-git-action/actions
- GitHub Settings: https://github.com/westermost/axon-demo-git-action/settings

---

## Tips

1. **Bookmark các AWS console links** để truy cập nhanh
2. **Screenshot các bước** để tham khảo sau
3. **Lưu thông tin** vào file text để không phải tìm lại
4. **Stop EC2** khi không dùng để tiết kiệm chi phí
5. **Check S3 costs** - xóa old results định kỳ
6. **Test với t3.small** trước, nếu chậm thì nâng lên t3.medium

---

## Cost Estimate

**Ước tính chi phí (us-east-1):**

- EC2 t3.medium: ~$0.04/hour
- S3 storage: ~$0.023/GB/month
- Data transfer: Free tier 100GB/month

**Ví dụ:** Chạy 10 tests/ngày, mỗi lần 10 phút:
- EC2: 10 phút × 10 lần = 100 phút/ngày ≈ $0.07/ngày
- S3: ~100MB results ≈ $0.002/tháng

**Tổng:** ~$2-3/tháng cho usage thông thường
