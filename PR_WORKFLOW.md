# Pull Request Workflow Guide

## Overview

Workflow tự động chạy tests trên AWS EC2 khi tạo hoặc cập nhật Pull Request.

## Triggers

Workflow chạy tự động khi:
- ✅ Mở PR mới (opened)
- ✅ Push thêm commits vào PR (synchronize)
- ✅ Mở lại PR đã đóng (reopened)

## Step-by-Step Guide

### 1. Tạo Branch Mới

```bash
# Checkout branch mới từ main
git checkout main
git pull origin main
git checkout -b add-new-test
```

### 2. Thêm Test Case

Ví dụ: Thêm test vào `tests/test_simple.py`:

```python
def test_list():
    """Test list operations"""
    my_list = [1, 2, 3, 4, 5]
    assert len(my_list) == 5
    assert sum(my_list) == 15
    assert my_list[0] == 1
```

### 3. Commit và Push

```bash
git add tests/test_simple.py
git commit -m "Add test_list: test list operations"
git push origin add-new-test
```

### 4. Tạo Pull Request

**Option A: Qua GitHub Web**
1. Vào repository trên GitHub
2. Click "Compare & pull request"
3. Điền title và description
4. Click "Create pull request"

**Option B: Qua GitHub CLI** (nếu đã cài `gh`)
```bash
gh pr create \
  --title "Add test_list: test list operations" \
  --body "Added new test case to verify list operations" \
  --base main \
  --head add-new-test
```

### 5. Workflow Tự Động Chạy

Sau khi tạo PR:
- ✅ GitHub Actions tự động trigger workflow
- ✅ Cleanup old test data (>1 hour) và kill servers cũ
- ✅ Clone repository và checkout đúng branch/commit của PR
- ✅ Tests chạy trên EC2 instance (Singapore) với code từ PR
- ✅ Allure report được generate
- ✅ Results upload lên S3
- ✅ Start HTTP server mới trên port động (8000-8099)

**Lưu ý**: 
- Workflow sẽ test chính xác code trong PR, không phải code từ main branch
- Mỗi workflow run có port riêng, không conflict khi chạy đồng thời
- Old servers (>1 hour) tự động cleanup để tiết kiệm tài nguyên

### 6. Xem Kết Quả

**Trong PR:**
- Check status ở tab "Checks"
- Click "Details" để xem workflow logs

**Xem Reports:**
- Option 1: `http://<EC2-IP>:<PORT>` (fastest) - Port hiển thị trong workflow output
- Option 2: S3 URL trong workflow logs
- Option 3: Download từ S3

## Workflow Configuration

File: `.github/workflows/test-aws-ec2.yml`

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch:
```

## Benefits

### 1. Automatic Testing
- Không cần manual trigger
- Mỗi PR đều được test tự động
- Catch bugs sớm trước khi merge

### 2. Consistent Environment
- Tests chạy trên EC2 (giống production)
- Không phụ thuộc local environment
- Reproducible results

### 3. Fast Feedback
- Kết quả trong 3-5 phút
- Allure report chi tiết
- Easy to debug failures

### 4. Code Review Integration
- Test status hiển thị trong PR
- Reviewers thấy test results
- Block merge nếu tests fail (optional)

## Example Workflow

```bash
# 1. Tạo branch
git checkout -b fix-bug-123

# 2. Fix bug và thêm test
vim tests/test_simple.py

# 3. Commit
git add tests/test_simple.py
git commit -m "Fix bug #123: Add validation test"

# 4. Push
git push origin fix-bug-123

# 5. Tạo PR (auto-trigger workflow)
gh pr create --title "Fix bug #123" --body "Added validation"

# 6. Xem kết quả
# → Vào PR trên GitHub
# → Click "Checks" tab
# → Xem Allure report
```

## Troubleshooting

### Workflow không chạy
- ✅ Check workflow file có trong `.github/workflows/`
- ✅ Verify trigger events đúng
- ✅ Check GitHub Actions enabled trong repo settings

### Tests fail trên EC2
- ✅ Xem workflow logs để debug
- ✅ Check EC2 instance đang chạy
- ✅ Verify dependencies installed correctly

### Report không accessible
- ✅ Check security group mở port range 8000-8099
- ✅ Verify EC2 public IP
- ✅ Check port number trong workflow output
- ✅ Check S3 bucket permissions

### Workflow test sai code (test code từ main thay vì PR)
- ✅ Verify workflow có checkout đúng branch:
  ```bash
  git fetch origin ${{ github.ref }}
  git checkout ${{ github.sha }}
  ```
- ✅ Check workflow logs phần "Current branch/commit"

### Allure report hiển thị kết quả cũ
- ✅ Mỗi workflow run có port riêng, không bị conflict
- ✅ Check đúng port trong workflow output
- ✅ Old servers (>1 hour) tự động cleanup
- ✅ Nếu cần xem report cũ, check S3:
  ```
  https://kiemtraxe.s3.ap-southeast-1.amazonaws.com/<RUN_ID>/allure-report/index.html
  ```

### Multiple PRs chạy đồng thời
- ✅ Mỗi workflow có port riêng (8000 + run_number % 100)
- ✅ Không conflict, không ghi đè report
- ✅ Mỗi run có RUN_ID unique
- ✅ Test directories và servers độc lập

## Technical Details

### GitHub Context Variables
Workflow sử dụng các biến sau để checkout đúng code:
- `github.ref`: Reference của PR (e.g., `refs/pull/1/merge`)
- `github.sha`: Commit SHA chính xác của PR head
- `github.repository`: Repository name (e.g., `westermost/axon-demo-git-action`)

### Checkout Process
```bash
# 1. Clone repository
git clone https://github.com/${{ github.repository }}.git .

# 2. Fetch PR branch
git fetch origin ${{ github.ref }}

# 3. Checkout exact commit
git checkout ${{ github.sha }}

# 4. Verify
git log -1 --oneline
```

Điều này đảm bảo tests chạy với code chính xác từ PR, không phải main branch.

## Best Practices

### 1. Small PRs
- Mỗi PR nên có ít changes
- Dễ review và test
- Faster feedback

### 2. Descriptive Commits
```bash
# Good
git commit -m "Add validation test for user input"

# Bad
git commit -m "update test"
```

### 3. Test Locally First
```bash
# Chạy tests local trước khi push
pytest tests/ -v
```

### 4. Clean Up Branches
```bash
# Sau khi merge PR, xóa branch
git branch -d add-new-test
git push origin --delete add-new-test
```

## Cost Considerations

- Mỗi PR trigger = 1 workflow run (~3-5 phút)
- EC2 t3.medium: ~$0.04/hour
- Mỗi run cost: ~$0.003-0.005
- 100 PRs/month: ~$0.50

**Recommendation**: Keep EC2 running nếu có nhiều PRs, stop khi không dùng.

## Next Steps

- [ ] Add branch protection rules (require tests pass)
- [ ] Add status badges to README
- [ ] Configure notifications (Slack/Email)
- [ ] Add code coverage reports
- [ ] Implement auto-merge for passing tests
