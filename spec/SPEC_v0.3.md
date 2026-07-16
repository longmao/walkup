# Walk Up · 第二阶段 Spec v0.3

> **版本**：v0.3（2026-07-16 · Cloud Build / Test / Distribute）
> **配套**：HANDOFF.md / `spec/SPEC.md`（v0.2 今日已过 · 历史）/ README / Sources
> **前置**：Apple Developer 申请通过（SSN 1-3d）+ 个人账户 longmaodashu@gmail.com
> **战略 wedge 锁死**：free + CoreMotion 硬件可靠 + 永久无订阅

---

## 0. 上下文（60 秒读懂）

- **今日（v0.2）**：模拟器跑通 · 3 commit 推 GitHub ✅
- **明天起（v0.3）**：Apple Developer 拿到 → Cloud Build / Test / Distribute / 7-day gate
- **4 件事流水线**：Cloud Build（Xcode Cloud）→ Test（TestFlight 内 100 → 外 10k）→ Distribute（ASC Submit）→ 7-day gate

## 1. tech-agent 必读 6 文件
1. HANDOFF.md · 2. **ai-fleet/docs/decisions/step-alarm/09-positioning.md**（**先读**）· 3. README.md · 4. Sources/*.swift · 5. RECAP_2026-07-16.md · 6. spec/SPEC.md（v0.2）

## 2. 4 阶段流水线（命令级 · Human 拍关键闸）

| # | 阶段 | 关键命令 | Human 拍 | Agent 干 |
|---|---|---|---|---|
| 1 | **Apple Developer + Bundle ID** | ASC → My Apps → + New App | 付费 / SSN / 凭证 | metadata + 配额 |
| 2 | **Cloud Build** | Xcode → Create Workflow → push main | 选 plan / 选 product | Xcode Cloud config |
| 3 | **Test** | `altool --upload-app` + TestFlight groups | 真机 6 步 QA / 内部 100 邀请 | .p8 / JWT / 自动化 upload |
| 4 | **Distribute** | ASC → + Version → Submit | Privacy 问卷 / Review notes / Submit | 3 截图 6.7"/6.5"/5.5" |
| 5 | **7-day gate** | Mixpanel + ASC API | D7 拍 6/8 闸决策 | 拉数据 + dashboard |

## 3. 5 Red Lines（沿用 v0.2 · 别动）
🔒 事以密成 · 🇺🇸 US only · 💸 永久 free · 🚫 别 clone Erly · ⏱ 1 天 1 功能

## 4. 16 Forbidden（沿用 11 + 🆕 第二阶段 5 加）
**沿用**：订阅/IAP/广告 · Vision · HealthKit · launch 前 tips/share/rate · 仿 Erly · "best alarm" · v1 中国 · ATT · 用户账号 · 扩 scope · Speech 切
**🆕 加**：第三方 SDK · Sign in with Apple（无社交 = 不接；用任一三方即强制） · App Preview 带音乐（版权） · 截图美化过度（与 UI 不符 = Review 红线） · App Review 不沟通（review notes 写清减拒）

## 5. 5 闸 Hard Bar（harness）
- **Gate 1**：Spec ≤100 行（v0.3 当前 87 行）
- **Gate 2**：Xcode Cloud build exit 0
- **Gate 3**：TestFlight 内部 6 步 QA 全过
- **Gate 4**：5 闸定义齐
- **Gate 5**：跨模型 review（minimax → `cc-glm` 关键 review）

## 6. Loop 思想（4 阶段每阶段都跑）
- 假设 → 拆 → 最小实验 → 证据 → 判定 → 沉淀
- **good-enough bar**：Dev 通过 → Cloud exit 0 → 内部 6 步过 → Submit "Waiting" → 7-day gate

## 7. Apple 资源整合（4 件事对应）

| 资源 | 用法 | 状态 |
|---|---|---|
| **Xcode Cloud** | push → 自动 build · 25h/月免费 → $49.99/100h | **必用** |
| **TestFlight** | 内 100 / 外 10k / 30 设备 | **必用** |
| **App Store Connect API** | `altool` + JWT 自动化 upload + 报表 | **必用** |
| **SF Symbols 7** | 7000+ icon | **必用**（Asset 0 成本） |
| StoreKit 2 / CloudKit / Foundation Models / Sign in with Apple | — | 不（free/不上云/1 功能/无社交） |

## 8. tech-agent 跑顺序
1. 读 6 必读（**先 09-positioning**）
2. Apple Developer 结果（杨总拍）→ 3 凭证配（.p8 + Key ID + Issuer ID 存 `~/Library/Application Support/WalkUp/credentials/`）
4. Bundle ID 注册 + ASC 创建
5. Asset（icon + 3 截图）→ 杨总拍
6. Privacy 部署（GH Pages / walkup-privacy）
7. Xcode Cloud workflow 配
8. Archive + Upload + TestFlight 内部
9. 真机 6 步 QA
10. TestFlight 外部（100+ 邀请 / 网红）
11. ASC metadata + Review notes（README §9 原文）
12. Submit（24-48h）· 13. 7-day gate

## 9. Risk Gates
- App Store 拒绝（不在 09-positioning §⑨）→ 问杨总
- 真机 6 步失败 → 修 / 砍
- 外部 KOL < 3 回复 → 扩范围
- 审核超 7d → 问杨总
- 7-day gate 4-5/8 → 紧 UX/ASO 不 pivot
- 上架 1★ 暴涨 → 紧急 hotfix

## 10. 验收
- 杨总 review → OK → Apple Developer 通过后启动
- 4 阶段每阶段闸过 = 进下一阶段
- 7-day gate 6/8 闸过 → v1.1（AlarmKit iOS 26 + watchOS complications）
- ≤ 3/8 → pivot mechanic · 保留 wedge
