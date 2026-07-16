# Walk Up · v0.3 Phase 2 Cloud Build · Xcode Cloud Workflow Plan

> **基线**：SPEC_v0.3.md §2 阶段 2 = Cloud Build 核心
> **账户**：longmaodashu@gmail.com · Apple Developer Individual（SSN 1-3d 通过后启动）
> **5 URL 实爬**：xc-overview · xc-configure · xc-distribute · xc-test · xc-envvars

---

## 1. Apple Developer Program 前置（杨总拍）

### Individual 申请
入口 https://developer.apple.com/programs/enroll/ → Individual / Solo · $99/yr · SSN + 姓名 → 1-3 工作日通过。账单 `~/Documents/Apple/DeveloperProgramInvoice.pdf`

### ASC 拿 3 凭证
ASC → Users and Access → Keys → **App Store Connect API** → Generate Team Key → 拿 `Key ID`(10位) / `Issuer ID`(UUID) / `AuthKey_XXXXXXXXXX.p8`(仅下载一次)。存 `~/Library/Application Support/WalkUp/credentials/AuthKey_XXXXXXXXXX.p8`，**chmod 600** + 不入 git

### Bundle ID + Team ID
ASC → Certificates, Identifiers & Profiles → Identifiers → + → App IDs → Explicit → `com.longmaodashu.walkup`（永不可改）· 勾 Background Modes（后台 timer）· 不勾 IAP / Sign in with Apple / HealthKit / CloudKit（v0.3 16 Forbidden）· Team ID：ASC → Membership → 10 位 → 写入 `~/.config/walkup/team_id`

---

## 2. Xcode Cloud Workflow 配置（**核心**）

### 入口
Xcode → Report navigator → Cloud button → Get Started → 选 Product（WalkUp scheme 已 archive）→ Create Workflow

### Workflow 4 段结构
```
General:    Name "WalkUp - Main" · Description auto-build on main push
Environment: Xcode 27.0 beta · macOS 15 · iOS Sim iPhone 15 (iOS 27) · arm64
Start:      Branch Changes main · PR target main · Tag v* · Schedule Mon 04:00
Actions:    analyze → build-for-testing → test → archive
Post:       Slack notification + TestFlight Internal "Core Team"
```

### 完整 JSON schema（App Store Connect API request body，非声明式配置）

> Xcode Cloud 无 declarative config；JSON 是 `POST /v1/ciWorkflows` / `PATCH /v1/ciWorkflows/{id}` 的 `CiWorkflowCreateRequest` body。日常配走 Xcode UI（Report navigator → Cloud → Get Started）。

```json
{
  "name": "WalkUp - Main",
  "description": "Auto-build on push; test; archive; distribute to TestFlight internal",
  "repository": { "id": "REPO_UUID_FROM_GITHUB_INSTALL" },
  "xcodeVersion": "27.0",
  "macOSVersion": "15.0",
  "triggerConditions": {
    "branchChanges":    [{ "branch": "main", "actions": ["build","test","archive"] }],
    "pullRequestChanges": [{ "targetBranch": "main" }],
    "tagChanges":       [{ "tagPattern": "v*", "actions": ["build","archive"] }],
    "schedule":         { "frequency": "weekly", "days": ["Mon"], "hour": 4 }
  },
  "actions": [
    { "type":"analyze", "scheme":"WalkUp", "platform":"iOS" },
    { "type":"build",   "scheme":"WalkUp", "platform":"iOS", "configuration":"Debug" },
    { "type":"test",    "scheme":"WalkUp", "platform":"iOS",
      "destination":"platform=iOS Simulator,name=iPhone 15,OS=27.0",
      "testPlan":"AllTests" },
    { "type":"archive", "scheme":"WalkUp", "platform":"iOS", "configuration":"Release" }
  ],
  "postActions": [
    { "type":"slackNotification",     "webhookURL":"https://hooks.slack.com/services/T.../B.../XXX" },
    { "type":"testflightDistribution","groups":["Core Team (Internal)"] }
  ]
}
```

### 4 Action 含义
**analyze** = `xcodebuild analyze` 静态 lint · **build** = `xcodebuild build-for-testing` 不跑测试只编译（smoke）· **test** = `xcodebuild test-without-building` 跑 XCTest + UI Test（≤100 device configs 并行）· **archive** = `xcodebuild archive` → .xcarchive → code-sign → TestFlight/ASC

### 凭证传 workflow（Environment Variables）
- Workflow → Environment → 加 3 自定义变量：`ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_PATH`
- 自定义 build script 里引用 `cat $ASC_KEY_PATH`（altool 备用）

---

## 3. Git 集成

### GitHub App（Xcode 内一键，**非 deploy key**）
Workflow 配完 → Review Workflow sheet → Grant Access → GitHub OAuth → 选 `longmaodashu/WalkUp` → **Install Xcode Cloud GitHub App**（org/repo 级 read-only · GitLab/Bitbucket 走 OAuth）

### 触发链路
`git push origin main` → GitHub App 通知 → Xcode Cloud poll → 自动 build（< 60s 启动）· 跳过：commit 含 `[ci skip]` · Auto-cancel：同 branch 新 commit 自动取消 in-progress（默认 ON）

---

## 4. TestFlight 自动分发

### Internal Group（先开，1-100 tester）
ASC → TestFlight → Internal Testing → + "Core Team" → email 邀请 → 装 TestFlight app → 即时收 build（无需 review）

### External Group（后开，≤ 10,000 tester · 必须先有 internal group）
ASC → TestFlight → External Testing → + "Beta Users" → **必经 Beta App Review (24-48h)** · 单 tester ≤ 30 设备 · build 自动 90 天过期

### Workflow post-action
加 TestFlight Distribution → 选 group → archive 后自动上传

---

## 5. App Store 自动分发

### ASC API（生产路径）
- Workflow post-action 加 **App Store Distribution** → 选 build → validate → Submit for Review
- 提交后人工加 Review Notes + 6.7"/6.5"/5.5" 截图

### altool CLI（备用上传）

```bash
# JWT 生成（≤ 20 min 寿命 · 长 flow 重新 mint）
HEADER=$(echo -n '{"alg":"ES256","kid":"'$ASC_KEY_ID'","typ":"JWT"}' | base64 | tr '+/' '-_' | tr -d '=')
PAYLOAD=$(echo -n '{"iss":"'$ASC_ISSUER_ID'","iat":'$(date +%s)',"exp":'$(($(date +%s)+1200))',"aud":"appstoreconnect-v1"}' | base64 | tr '+/' '-_' | tr -d '=')
UNSIGNED="$HEADER.$PAYLOAD"
SIG=$(echo -n "$UNSIGNED" | openssl dgst -sha256 -sign "$ASC_KEY_PATH" | base64 | tr '+/' '-_' | tr -d '=')
JWT="$UNSIGNED.$SIG"

xcrun altool --upload-app -f WalkUp.ipa -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```
> 替代品：**Transporter**（Mac App Store）现 Apple 推荐取代 altool · TestFlight review ≤ 6 builds / 24h

### Archive 分发方式（v0.3 选 Internal Only）
- **TestFlight & App Store**（默认）→ 可 Submit for Review
- **TestFlight Internal Only** → 限 internal group，**不能去 App Store**（WalkUp v0.3 选它 · v1.1 release 改 default）

### 加密合规（Info.plist 必加）
```xml
<!-- WalkUp 不加密 → 跳过 export compliance 问卷 -->
<key>ITSAppUsesNonExemptEncryption</key><false/>
```

---

## 6. 配额管理（25h/月免费够用）

### 5 档订阅（xc-overview 实抓）
| 档位 | 价格/月 |
|---|---|
| 25 compute hours | **免费**（Program 内置） |
| 100 | $49.99 |
| 250 | $99.99 |
| 1,000 | $399.99 |
| 10,000 | $3,999.99 |

### 1 人业余计算
- 1 build ≈ 3-5 min · 日 5 push = 25 min/day ≈ 12 h/月（build + test + archive）
- 留 13h 给 tag release + weekly UI test → **25h 够**

### 监控
```bash
curl -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/xcodeCloudUsage"
```
ASC → Settings → Notifications → 80% / 100% threshold 邮件预警

---

## 7. 失败诊断 + 重试

### Log 路径
- **Xcode**：Report navigator → Cloud → 选 build → 展开 Actions → Logs → 实时 xcodebuild 输出
- **ASC web**：My Apps → WalkUp → Xcode Cloud tab → Builds → 选 build → Logs
- 30 天后过期 → 下载存档（App Store 版本必存档含 symbol）

### 捕获失败 + Slack 通知（build script）
```bash
if [ "$CI_XCODEBUILD_EXIT_CODE" -ne 0 ]; then
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"❌ Build #$CI_BUILD_NUMBER failed: $CI_BUILD_URL\"}" \
    "$SLACK_WEBHOOK"
fi
```

### 5 Common Errors
`No signing certificate` → ASC Profiles 自动管理 · `Bundle ID mismatch` → Xcode target Signing match ASC · `PRODUCT_BUNDLE_IDENTIFIER overwritten` → 删 .xcconfig target 显式设 · `Dependencies unavailable` → 私有 SPM/Pods 加 SSH key 到 Workflow SCM · `Test failed iPhone 15 sim` → Environment 选 Xcode 27 自带 sim

### 重试（**无 auto-retry policy**）
Xcode Cloud 无用户可配 retry · transient 错手动：ASC → Build → More → **Rebuild**（同 commit）/ Start Build（latest）· Auto-cancel 同 branch 新 commit → in-progress build 自动取消（默认 ON）

### 关键 env vars（xc-envvars 实抓）
`CI_BUILD_NUMBER` `CI_BUILD_ID` `CI_COMMIT` `CI_BRANCH` `CI_TAG` `CI_PRODUCT` `CI_BUNDLE_ID` `CI_TEAM_ID` `CI_WORKFLOW` `CI_XCODE_SCHEME` `CI_XCODEBUILD_EXIT_CODE` `CI_ARCHIVE_PATH` `CI_APP_STORE_SIGNED_APP_PATH` `CI_RESULT_BUNDLE_PATH`（完整 46 个见 [Apple docs](https://developer.apple.com/documentation/Xcode/Environment-variable-reference)）

---

## 验收（harness）Gate 1: ≤200 行 ✅ · Gate 2: local build exit 0 · Gate 3: Cloud first build exit 0 · Gate 4: push main → 5min build + Internal 收到 · Gate 5: altool 上传成功 · Gate 6: hours ≤ 25

---

## tech-agent 执行顺序

```bash
mkdir -p ~/Library/Application\ Support/WalkUp/credentials/ && chmod 600 ~/Library/Application\ Support/WalkUp/credentials/AuthKey_*.p8
echo "ASC_KEY_ID=XXXX" > ~/.config/walkup/asc.env && echo "ASC_ISSUER_ID=YYYY" >> ~/.config/walkup/asc.env
open -a Xcode ~/Developer/WalkUp/WalkUp.xcodeproj   # → Cloud → Get Started → 4 段配 → Grant GitHub
git push origin main   # 监控 https://appstoreconnect.apple.com/apps/APP_ID/xcodeCloud
# ASC → TestFlight → Internal → invite longmaodashu@gmail.com
```

---

**约束锁死**：Xcode 27 beta · trigger=push main + tag v* · Action 链 analyze→build→test→archive · TestFlight Internal→External→App Store · 自动重试 3 次 + Slack webhook