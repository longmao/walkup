# Walk Up · 实施 Spec v0.2

> **版本**：v0.2（2026-07-16 · 从 v0.1 缩到今日 3 步）
> **配套**：HANDOFF.md / README.md / Sources/*.swift / Resources/*
> **角色**：tech-agent 跑的实施 spec（代码 9 swift / 662 行已写好，剩 ship 流程）
> **战略 wedge 锁死**：free + CoreMotion 硬件可靠 + 永久无订阅

---

## 0. 上下文（60 秒读懂）

- **产品**：Walk Up = CoreMotion 步数闹钟（**1 个功能**：走 N 步才停）
- **今天目标 = 模拟器跑起来**（**不** ship / **不**上架 / **不**真机）
- **今晚**：试 Apple Developer 申请（SSN 1-3d 审核，**今天跳过**）
- **明天起**：Apple Developer 通过 → 真机 QA → ASC → Submit（详见 §2 future 4 步）
- **Wedge**：Erly 订阅（29% 1★）+ Erly Vision flaky → **free + CMPedometer 硬件可靠 + 永远无订阅**
- **个人账户**：longmaodashu@gmail.com（gh token 失效待修）
- **仓库**：`/Users/vincent/work/ai-fleet-projects/stepup/` → push GitHub

## 1. tech-agent 必读 5 文件（按顺序）
1. **HANDOFF.md**（10 段战略 + next actions + forbidden）
2. **ai-fleet/docs/decisions/step-alarm/09-positioning.md**（战略/ASO/合规/闸门 = **必读**）
3. **README.md**（Xcode 5 步操作）
4. **Sources/*.swift**（9 文件 / 662 行已写）
5. **erly/summary.md**（299 reviews wedge 证据）

## 2. 今日 3 步（v0.1 7 步 → v0.2 缩到 3 步 · 未来 4 步 deferred）

| # | 步骤 | 命令级 | Human 拍 | Agent 干 |
|---|---|---|---|---|
| 1 | **编译验证** | `xcodebuild -project StepUp.xcodeproj -scheme StepUp -destination 'platform=iOS Simulator,name=iPhone 17' build` | 修失败 bug | 建 .xcodeproj + 跑命令 |
| 2 | **模拟器跑通** | `xcrun simctl install booted build/...app && xcrun simctl launch booted com.walkup.StepUp` | 录屏验 | 安装 + 启动 + 截图 |
| 3 | **GitHub push** | `git init && git add . && git commit -m "init" && gh repo create walkup --public --source=. --push` | 修 gh token | 配 SSH:443 + commit + push |

**未来 4 步**（明天起 · Apple Developer 通过后）：真机 QA → Asset → Privacy 部署 → ASC + Submit → 7-day gate

## 3. 5 Red Lines（**别动**）
- 🔒 **事以密成**：独立 Apple ID / Mac / 凭证 / git（**别碰主业公司 IP**）
- 🇺🇸 US 市场 v1 only
- 💸 永久 free（**无 IAP / ads / subscription / tip** = 品牌承诺）
- 🚫 别 clone Erly 视觉
- ⏱ 1 天 1 个功能 = 极简

## 4. 11 Forbidden（**不踩**）
❌ 订阅/IAP/广告 · ❌ Vision HumanBodyPose · ❌ HealthKit · ❌ launch 前 tips/share/rate · ❌ 仿 Erly/Wayk 视觉 · ❌ "best alarm" 商标词 · ❌ v1 进中国 · ❌ App Tracking Transparency · ❌ 用户账号/sign-in · ❌ 扩 scope（notes/journal/habits/stats） · ❌ 切到 Speech 语音产品

## 5. 5 闸 Hard Bar（harness 思想 · 反飘护栏）
- **Gate 1**：Spec ≤ 100 行（v0.2 当前 99 行）
- **Gate 2**：xcodebuild exit 0
- **Gate 3**：模拟器跑通（录屏不崩）
- **Gate 4**：5 闸定义齐（本文档 §5 + handoff §7）
- **Gate 5**：跨模型 review（编码 minimax → 关键 review 切 `cc-glm` session）

## 6. Loop 思想（**今日 3 步每步都跑 loop**）
- **假设 → 机制 → 最小实验 → 证据 → 判定 → 沉淀**
- 例 Step 1：假设 9 swift 可编译 → 拆 `xcodebuild` 机制 → 跑最小实验 → exit 0 = 证据 → 判定 OK → 沉淀进 spec-evidence
- **good-enough bar**：3 闸过 = 停（不重写 / 不优化 / 不扩）

## 7. Apple 资源整合 + Xcode 27 新能力（**关键新增杠杆**）

| 资源 | 用法 |
|---|---|
| **Xcode 27** ✓ 已就位 | iOS 27.0 runtime + 11 模拟器 |
| 🆕 **Agentic Coding**（Xcode 27 新） | OpenAI Codex + Claude Agent 内置 → tech-agent 可直挂 coding tools |
| 🆕 **External Agent Access**（Xcode 27 新） | MCP 协议 → 其他 agent 接 Xcode = **build/test/搜 Apple docs/修 issue** |
| **TestFlight** | 内部 100 / 外部 10k（明天起） |
| **App Store Connect API** | `altool` + JWT 自动化（明天起） |
| **CMPedometer** | iOS 17+ · 模拟器不 work → 走长按 3s 兜底验证 |

## 8. tech-agent 跑顺序（harness + loop 闭环）
1. 读 5 必读文件（**先 09-positioning**）
2. **Step 1 编译验证**（建 .xcodeproj + xcodebuild）→ exit 0 ✓
3. **Step 2 模拟器跑通**（xcrun simctl install/launch + 录屏）→ 录屏 ✓
4. **Step 3 GitHub push**（git init + commit + 配 SSH:443 + `gh repo create`）→ push 成功 ✓
5. 任何 forbidden 触发 → **立即停手问杨总**

## 9. Risk Gates（Escalation Triggers · v0.2 缩）
- 编译失败 = iOS 27 SDK 与 swift 代码不兼容 → 问杨总
- gh token 失效 = 走 SSH:443 配置（memory `ssh-443-github.md`）→ 修到 push 通
- Apple Developer 申请不符 = 走 Individual SSN 流程（1-3d）→ 晚上试

## 10. 验收
- **今日**：模拟器跑通（录屏）+ GitHub push 成功 = 3 闸 PASS
- **今晚**：试 Apple Developer 申请（结果记录）
- **明天起**：按未来 4 步推进
- 杨总 review → OK → tech-agent 启动 Step 1
