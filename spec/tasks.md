# Walk Up · v0.3 Phase 2 · tasks.md

> **基线**：`SPEC_v0.3.md` + `plan.md` · 4 阶段流水线（Cloud Build / Test / Distribute / 7-day gate）
> **Execution Contract**：9 字段 / 每行 1 任务 / `dangerous` 必带（高=凭证/远程写/上架 · 中=写文件/装包 · 无=读 grep）
> **status**：pending → in_progress → done

---

## A. 阶段 1 · Apple Developer + 凭证

| ID | action | agent | input | output | acceptance | allowed_tools | forbidden_tools | dangerous | status |
|---|---|---|---|---|---|---|---|---|---|
| D1 | Apple Developer Individual 申请（$99/yr · SSN 1-3d） | human | developer.apple.com/programs/enroll | 通过邮件 + 账单 PDF | ASC 可登录 longmaodashu@gmail.com | Browser, ASC web | altool,JWT 自动 | **高** | pending |
| D2 | ASC API Team Key 生成 + 3 凭证存 `~/Library/Application Support/WalkUp/credentials/` | human | ASC → Users and Access → Keys | Key ID + Issuer ID + AuthKey_*.p8 chmod 600 | 3 文件齐 + 不入 git | Browser, chmod, mkdir | public 上传 | **高** | pending |
| D3 | Bundle ID `com.longmaodashu.walkup` 注册（勾 Background Modes audio · 不勾 IAP/SiA/HK/CK） | human | ASC → Identifiers → + App ID | Bundle ID 列表命中 | 与 Xcode target 一致 | Browser | auto API | **高** | pending |

## B. 阶段 2 · Cloud Build

| ID | action | agent | input | output | acceptance | allowed_tools | forbidden_tools | dangerous | status |
|---|---|---|---|---|---|---|---|---|---|
| D4 | xcodegen regenerate + xcodebuild build 验 `ITSAppUsesNonExemptEncryption` 注入 | tech-agent | project.yml + Info.plist | built `.app/Info.plist` 命中 key | `plutil -p` 含 `<false/>` | Bash, xcodegen, xcodebuild, plutil | 上传/签字 | **中** | pending |
| D5 | Xcode → Report navigator → Cloud → Get Started → 4 段配（General/Environment/Start/Actions） | human+tech | Xcode UI | Workflow `WalkUp - Main` 创建 | GitHub App 装好 + start conditions 命中 main | Xcode UI, GitHub OAuth | altool 直传 | **中** | pending |
| D6 | Workflow Environment Variables 注入 `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_PATH` | human | Xcode Cloud Workflow Env tab | 3 自定义变量 | build script 引用不报 missing | Xcode UI | 硬编码 .p8 | **高** | pending |
| D7 | push main → 首 build exit 0 + Slack 通知 | tech-agent | git push origin main | Build #1 exit 0 + Slack 收到 | 25h 配额扣 < 1h | git, curl Slack | manual upload | **中** | pending |

## C. 阶段 3 · TestFlight

| ID | action | agent | input | output | acceptance | allowed_tools | forbidden_tools | dangerous | status |
|---|---|---|---|---|---|---|---|---|---|
| D8 | Internal Group `Core Team` 建 + 邀请 longmaodashu@gmail.com | human | ASC → TestFlight → Internal | invite 邮件 | TestFlight app 即时收到 build | Browser, TestFlight | 不合规打包 | **高** | pending |
| D9 | 真机 6 步 QA（建闹 → 步数授权 → 屏幕常亮 → 步行 10 → 响铃停止 → 后台） | human+qa | TestFlight app + iPhone 真机 | QA 6/6 pass | 全过才进 External | TestFlight, 真机 | sim 替代 | **中** | pending |
| D10 | External Group `Beta Users` 建 + 100+ 邀请（**必经 Beta App Review 24-48h**） | human | ASC → TestFlight → External | ≥100 invite | 全部装 TestFlight 收到 build | Browser, email | 跳过 Beta Review | **高** | pending |
| D11 | 网红合作 SOP（外 1k 中筛 KOL：health/wellness/productivity · DM 模板 + 转化追踪表） | ops-agent | KOL list · DM template | 3 KOL 首轮回复 | KOL table 更新 + DM 发出 | Browser, Sheets | 买粉/批量关注 | **中** | pending |
| D12 | 娃参与 UX 验证（家长+娃 双视角 · 5-10 岁步数目标调整） | human+kid | TestFlight build + 娃试用 | 家长口径 + 娃口径各 1 段 | 家长 4/4 OK · 娃 3/4 OK 即可发外 | TestFlight, 真机 | sim 替代 | **中** | pending |

## D. 阶段 4 · Distribute + 7-day gate

| ID | action | agent | input | output | acceptance | allowed_tools | forbidden_tools | dangerous | status |
|---|---|---|---|---|---|---|---|---|---|
| D13 | Asset 三件（icon + 6.7"/6.5"/5.5" 截图）· 走 SF Symbols 7 + 系统截图 · **不美化过度** | human+tech | 模拟器/真机截图 | 3 PNG + icon 1024×1024 | UI 与截图 100% 符 · 无音乐 preview | xcrun simctl, SF Symbols app | Photoshop 美化 | **中** | pending |
| D14 | Privacy Policy 部署（GH Pages → walkup-privacy · 与 App Privacy 一致） | tech-agent | privacy-policy.html | gh-pages branch live | URL 可访问 + 与 Info.plist 一致 | git push gh-pages | inline PII | **中** | pending |
| D15 | ASC Submit（Privacy 问卷 + Review notes 写清减拒 + 3 截图 + Internal Only distribution 改 default） | human | ASC → + Version → Submit | "Waiting for Review" 状态 | 24-48h 后审 | Browser, ASC web | 沟通 Review 团队 | **高** | pending |
| D16 | 7-day gate · 拉数据（Mixpanel + ASC API + TestFlight metrics）→ D7 拍 6/8 闸决策 | ops-agent | Mixpanel events + ASC API | dashboard + 决策报告 | ≥6/8 过 → v1.1 · ≤3/8 → pivot | curl, Mixpanel, ASC API | 删数据 | **高** | pending |

## E. 5 闸 Hard Bar（harness）

| ID | action | agent | input | output | acceptance | allowed_tools | forbidden_tools | dangerous | status |
|---|---|---|---|---|---|---|---|---|---|
| G1 | Spec ≤ 100 行（实际 82）· 阻断 > 100 | harness | SPEC_v0.3.md | `wc -l` ≤ 100 | exit 0 | wc, grep | — | **无** | pending |
| G2 | Xcode Cloud build exit 0（首 push → 5min 内完成） | harness | git push main → Cloud | Build #N exit 0 | ASC Xcode Cloud tab 显示绿勾 | xcodebuild (remote) | — | **无** | pending |
| G3 | TestFlight 内部 6 步 QA 全过（见 D9） | qa-agent | 真机 + TestFlight app | 6/6 pass | QA sheet 全绿 | TestFlight app | — | **无** | pending |
| G4 | 5 闸定义齐（自身 G1+G2+G3 + G4 + G5 跨模型） | harness | spec/SPEC_v0.3.md §5 | 5 闸清单 | 与 SPEC 对得上 | grep | — | **无** | pending |
| G5 | 跨模型 review（minimax → `cc-glm` 关键 review · 海信 Harness 抗幻觉硬尺） | harness | cc-glm session | review report | exit 0 + 决策建议 | cc-glm CLI | — | **中** | pending |

---

**dangerous 等级说明**：高 = 凭证/远程写/上架/付费 · 中 = 写文件/装包/部署 · 无 = 读 grep/wc
**Forbidden 沿用**：订阅/IAP/广告 · Vision · HealthKit · launch 前 tips/share/rate · 仿 Erly · "best alarm" · v1 中国 · ATT · 用户账号 · 扩 scope · Speech 切 · **🆕** 第三方 SDK · **🆕** Sign in with Apple · **🆕** App Preview 带音乐 · **🆕** 截图美化过度 · **🆕** App Review 不沟通