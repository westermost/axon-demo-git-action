# GitHub Pages Setup Guide

Hướng dẫn enable GitHub Pages để publish Allure reports.

---

## STEP 1: Enable GitHub Pages

1. Vào repo: https://github.com/westermost/axon-demo-git-action
2. Click **Settings** tab
3. Click **Pages** (menu bên trái)
4. Trong **Source** section:
   - Chọn **GitHub Actions** (thay vì Deploy from a branch)
5. Click **Save**

---

## STEP 2: Run Workflow

### Option A: Tự động (khi push code)
- Workflow sẽ tự động chạy khi push lên master
- Đợi workflow hoàn thành (~2-3 phút)

### Option B: Manual trigger
1. Vào **Actions** tab
2. Click workflow **"Deploy Reports to GitHub Pages"**
3. Click **Run workflow**
4. Click **Run workflow** button

---

## STEP 3: Xem Report

Sau khi workflow hoàn thành:

**Report URL:**
```
https://westermost.github.io/axon-demo-git-action/
```

Hoặc:
1. Vào **Settings** → **Pages**
2. Xem link **Your site is live at...**
3. Click vào link

---

## Workflow Đã Tạo

### 1. pages.yml
- Chạy tests trên GitHub runners
- Generate Allure report
- Deploy lên GitHub Pages
- **Trigger:** Push to master hoặc manual

### 2. publish-report.yml
- Tự động publish report sau khi EC2 workflow hoàn thành
- Lưu reports theo run number
- **Trigger:** Sau khi "Playwright Tests on AWS EC2" hoàn thành

---

## Report URLs

### Latest report (từ pages.yml):
```
https://westermost.github.io/axon-demo-git-action/
```

### EC2 reports (từ publish-report.yml):
```
https://westermost.github.io/axon-demo-git-action/reports/1/
https://westermost.github.io/axon-demo-git-action/reports/2/
https://westermost.github.io/axon-demo-git-action/reports/3/
...
```

---

## Troubleshooting

### Issue 1: 404 Not Found

**Giải pháp:**
1. Verify GitHub Pages enabled
2. Check workflow đã chạy thành công
3. Đợi 1-2 phút để GitHub Pages deploy
4. Hard refresh browser (Ctrl+F5)

### Issue 2: Workflow fails

**Check:**
1. Xem logs trong Actions tab
2. Verify permissions trong workflow file
3. Check repo settings → Actions → General → Workflow permissions = "Read and write"

---

## Update Report

Mỗi lần push code hoặc run workflow, report sẽ tự động update.

**Xem history:**
- Latest: `https://westermost.github.io/axon-demo-git-action/`
- Run #1: `https://westermost.github.io/axon-demo-git-action/reports/1/`
- Run #2: `https://westermost.github.io/axon-demo-git-action/reports/2/`

---

## Tips

1. **Bookmark report URL** để truy cập nhanh
2. **Share link** với team để review test results
3. **Keep old reports** - workflow giữ lại reports cũ theo run number
4. **Custom domain** - Có thể setup custom domain trong Settings → Pages
