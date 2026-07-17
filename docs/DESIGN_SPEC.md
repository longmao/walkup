# Walk Up — Design & Interaction Upgrade Spec · **v0.2 (tight)**

> **Status:** Draft v0.2 enriched (web-fetcher 268 shot 调研 enrich §9) · 等杨总拍 3 条。
> **Hard constraints from 杨总 2026-07-17**：
> 1. **5 天内 App Store 提交审核**（D1 周一开工 → D5 周五 ship）
> 2. **不能模板化** —— 不准 `Form` 风格、不准 default DatePicker wheel、不准 SF Symbol 裸贴、不准 default tab bar、不准默认 SwiftUI section/row
> 3. **要有美感和质感** —— 走 editorial illustration + big type + 强叙事，配色/动效/排版每一档都要给品味证据
> **产品不重定位**：Walk Up = "walk to dismiss alarm" 不动；只在"被逼着起床"→"被温柔唤醒"这条情感曲线打磨。

---

## 1 · 设计路线 · **"Indie Editorial Sunrise"（仅此一条，不让选了）**

**参考标杆**（Dribbble 268 shot 调研 · 2026-07-17）：
- **karina_bondarenko · Alarmi** — 社交 + 习惯打卡 + 早起激励（起床仪式感标杆）
- **asol_design / Anna · Pastel UI Wellness iOS** — lavender + mint pastel，**wellness 范本**
- **strangehelix · asklepios/freud** — dark dashboard + AI · 高端调
- **uxcratelab · AI Alarm Clock** — multi-step unlock + AI 加持
- **DD_UIUX · Fitness Tracker UI Kit** — 圆环 + 高对比 action 派
- **Fireart-d · iOS Alarm Clock App** — iOS native 风对位，editorial 但不脱离系统
- **Tubik · Wellness Design System** — 微交互 / 设计系统参考

**不走**（明确划线）：
- Sleep Cycle / Pillow dashboard chart 堆叠（不是这条路）
- Alarmy 拍照 / 拼图 unlock 模板
- Default iOS 14/15 section + wheel picker（一眼就觉得是 demo）
- Default SwiftUI `TabView` / `Form` / `Section` / `Label` / `Stepper` / `Toggle` / `Slider`

**外部验证对位**（来自 agent §5 启示）：
- ✅ ring dial + sunrise gradient + mission card 三件套 是 2024-2026 主流 → 我们走对了
- ✅ dark by default 对位 sleep/alarm 主流化趋势
- ✅ pastel UI + 插画 wellness 主流 → **§2 加 pastel variant 给 onboarding**
- ✅ App Store Screenshots 须单独设计 → D5 已规划
- ➕ Widget / Dynamic Island 2024-2026 iOS 化必做 → **D6+ post-launch（不在 5 天内）**

---

## 2 · 视觉系统 v1 · **"Aurora Dawn Editorial"**

### Color palette（dark by default；早 5 点不该亮屏）
| Token | Hex | 用在 |
| --- | --- | --- |
| `bg/sky` | `#0E1320` | Setup 背景 / ringing 深空基底 |
| `bg/surface` | `#1A2238` | 卡片底层 |
| `bg/well` | `#252D44` | 凹陷区域 (slider track 等) |
| `accent/sunrise-start` | `#3D2A6E` | gradient 起点 (深紫) |
| `accent/sunrise-mid` | `#E26A4D` | gradient 中段 (粉橙) |
| `accent/sunrise-end` | `#F6C065` | gradient 终点 (暖金) |
| `accent/steady` | `#7B89F4` | 步数 / steady ring |
| `accent/goal` | `#6EE7B7` | 目标达成的 fill |
| `accent/emergency` | `#F87171` | 长按 fallback 进度环 |
| `text/primary` | `#F5F1E8` | 主体文字 (warm off-white) |
| `text/secondary` | `#A0A8BC` | 副文字 |
| `text/tertiary` | `#5A6178` | 弱化 (footer / debug 残留) |

**Onboarding 暖色变体**（Agent §5 启示 · pastel 配 dark 形成 emotional contrast）：
- `pastel/dusk` `#9F8AC9` (lavender · 对位 Anna/asol_design)
- `pastel/sun` `#F4B69C` (peach · 对位 Pastel 暖 trend)
- `pastel/sky` `#D1E3FA` (light blue · 配 Onboarding Step 1 远山)

**质感证据**：
- 主体字 `#F5F1E8` 而非纯白 —— 匹配 sunrise 暖感，"质感"就是这么出来
- 配色用 `.meshGradient` (iOS 26) 而非 `.linearGradient` —— 柔和的色块过渡而非生硬线性
- **双调系统**：主流程 dark + sunrise（已发生 = 强叙事）；onboarding pastel 暖（即将发生 = 友好邀请）—— emotional contrast

### Typography
- **Display / Time hero** —— `.system(size: 96, weight: .heavy, design: .rounded).monospacedDigit()` —— **不引第三方字体**（review 稳）
- **Hero subtitle** —— `.system(size: 17, weight: .regular)`
- **Body** —— default
- **Caption / footer** —— `.caption2`
- **数字一律 `.monospacedDigit()`** —— 防止 width 抖动
- **数字变化 `.contentTransition(.numericText())`** —— 自带翻牌感，不引 Lottie

### Iconography · SF Symbols 5 + custom outline
- 大部分用 SF Symbols（`figure.walk`、`alarm.fill`、`chevron.right` 等）
- **3 个 custom 路径**（Figma 手绘 → SwiftUI `Path`）：
  - **Sun-ray ring** —— Ringing 的 sunrise gradient 圆环（hero 元素）
  - **Step footprint** —— Setup hero + App icon
  - **Mountain horizon** —— onboarding 背景（远山轮廓，editorial 风的宁静感）

### Spacing & shape
- 8pt grid；4pt 微调
- Card `cornerRadius = 20`；hero time block `= 28`；button pill `= 9999`
- **不用 `.shadow()`** —— 质感靠 gradient + ultraThinMaterial + 1pt stroke 叠出来
- Material 用 `.ultraThinMaterial` (iOS 15+)—— 玻璃感而非死灰

### Motion DNA
- **Spring 通用** —— `.spring(response: 0.55, dampingFraction: 0.78)` —— 慢一档更有质感
- **Ringing 背景** —— `.meshGradient` + 1.5s 呼吸动画 (opacity 0.85 ↔ 1.0) 模拟晨光
- **Goal burst** —— `.symbolEffect(.bounce, value: success)` + radial gradient burst（不是 GIF）
- **数字变化** —— `.contentTransition(.numericText())` + spring
- **不引 `.easeInOut` 默认曲线** —— 全 spring，给节奏不机械

---

## 3 · 4 个 screens · **不重做产品逻辑，只重做视觉 + 交互**

### S1 · Alarm Setup · "Time hero card"
- **顶端留白 80pt** —— App Store screenshot 上 hero 时间 + 留白 就是封面
- **96pt 大字 time** 居中
- **副文案动态算 "Wake at 6:30 AM · In 8h 23m"**（不是静态标签）
- **下方 Steps card** —— 不是 stepper；是 horizontal 4 档 preset chip（10 / 25 / 50 / 100）+ ± button fine-adjust；选中态用 sunrise gradient fill 而不是纯橙
- **Day chips** —— 仍是 7 圆但加了 "Weekdays / Weekends / Every day" 三个快捷 toggle 在上方
- **底部 sticky**：Enable toggle（pill shape · 自定义 track · 滑块用 sunrise gradient fill 而非 default blue）+ 副文案 "Tomorrow at 6:30 AM"
- **底部 right**：`figure.walk.fill` icon button 测试当前 alarm → 立即跳 Ringing
- **整个 screen 不用 `Form`** —— 用 `ZStack` + `ScrollView` 自由排版

### S2 · Ringing · "Sunrise ring"（核心 · 最花心思）
- **满屏 sunrise gradient (mesh)** + 1.5s 呼吸
- **中心 = hero ring**：
  - 0% 时圆环是深紫，细描边
  - 每走 5 步，描边颜色从紫渐变到粉橙到暖金
  - 圆环角度从 5° (just-risen) → 180° (overhead)
  - **不是 default trim 0→1**，是自定义 Path with angle sweep 配合 sunrise palette
- **数字 hero = 步数**（位于环中心，`monospacedDigit` + `numericText()` 翻牌）
- **副文案三态**：`"23 steps to sunrise"` / `"Almost there"` / `"Sun's up ✓"`
- **Haptic progressive**：
  - 0-50%: 每 5 步一次 light tap (`UIImpactFeedbackGenerator(style: .light)`)
  - 50-80%: 每 3 步一次 medium tap
  - 80-100%: 每 1 步一次 heavy tap
  - 100%: success burst (`UINotificationFeedbackGenerator`)
- **Goal reached** —— 全屏金色 radial burst 200ms in / 600ms out + 文字 "Sun's up ✓" + 「Stop」 button fade in 600ms
- **Emergency fallback** —— 长按 3s，自定义 ring stroke fill 从 0→1 同步视觉反馈（不是 default filled button）
- **顶部时间** — `06:30` 小字淡入 + "Good morning"

### S3 · Onboarding · 3 步（首次启动）
- **Step 1 / Welcome** —— 远山 + sunrise hero illustration（编辑感手绘 SwiftUI Path）+ 大字 "Wake up by walking." + 副文案 "Free forever. No ads. No tracking." + 「Get started」 pill button
- **Step 2 / Motion permission** —— 解释 "Why we need motion" + 锁图标 + 「Enable motion」 pill button（触发 OS dialog）
- **Step 3 / Test alarm** —— "Try it now" → 触发 Ringing → 自动 dismiss 走完 → 「You're all set ✓」 confetti（symbol effect）
- **不是 `TabView` 多页** —— 是一页翻页（PageTabViewStyle + index 显示）

### S4 · About · 品牌叙事
- **顶部**：App icon (sized 88pt) + 名字 "Walk Up" + tagline "Walk to wake up."
- **中部 4 个 feature**：用 custom outline 图标 + 大字 label + 一行 description（不是 default Label）
- **底部**：Privacy policy / Version / GitHub link
- **不用 `Form`** —— 用 `VStack(spacing: 24)`

---

## 4 · Micro-interaction 总清单（**质感爆发点 · 这层决定"有质感"**

| # | 场景 | 设计 | 关键 API |
| --- | --- | --- | --- |
| M1 | Setup 进 Ringing | Setup 向下淡出 + Ringing 从底部 sunrise mesh 升起 (500ms spring) | `.matchedGeometryEffect` 可选 |
| M2 | Time 字翻牌 | `numericText()` + spring，不重布局 | `.contentTransition(.numericText())` |
| M3 | Enable toggle ON | 滑块带 sunrise gradient + 滑过的 track 透出 `(tri-tone mesh)` | `.tint(.meshGradient)` |
| M4 | Day chip toggle | scale 1.0→1.15→1.0 弹性反馈 | `.spring(response: 0.4, dampingFraction: 0.55)` |
| M5 | Steps preset 切换 | hero number spring 跟进 + 微 haptic | `.sensoryFeedback(.impact, trigger:)` |
| M6 | 圆环 fill per 5 steps | trim + 颜色 crossfade + light haptic | `CGMutablePath` + `withAnimation` |
| M7 | 接近 goal (≥80%) | symbol pulse + 文字 "Almost there" | `.symbolEffect(.pulse, by:)` |
| M8 | Goal burst | 全屏 radial gradient + confetti symbol effect | `.symbolEffect(.bounce)` + overlay gradient |
| M9 | Emergency 长按 3s | 自定义 Path stroke 同步 fill | `LongPressGesture(minimumDuration:)` |
| M10 | Tab switch (Setup ↔ About) | 整页内容 crossfade 200ms | `.transition(.opacity)` |
| M11 | Onboarding 进度 | 顶部 3 dot，current dot 用 sunrise gradient 拉宽 | `Capsule` + `frame(width:)` |
| M12 | Mesh gradient 呼吸 | Ringing 背景 1.5s 循环 | `TimelineView(.animation)` |

---

## 5 · **不模板化硬 guard**（防 `.Form`/`.wheel`/default style 复发）

- ❌ 不用 `Form` / `Section` / `Label`
- ❌ 不用 `DatePicker.wheel` / `.compact` default
- ❌ 不用 default `Toggle` / `Stepper` / `Slider`
- ❌ 不用 default `TabView` (要 customized bottom floating pill)
- ❌ 不用 `.bordered` / `.borderedProminent` default button style
- ❌ 不用 SF Symbol 直贴大尺寸（搭配 `symbolEffect` 才不土）
- ❌ 不用任何第三方字体 / 第三方 icon 库 / Lottie / Rive
- ❌ 不用 `.shadow()`（质感靠 gradient + material + stroke）
- ❌ 不用 `.easeInOut` / default animation

---

## 6 · 5 天路线 · **能交付 · 每步闭环**

| Day | 交付 | 验收 |
| --- | --- | --- |
| **D1** Mon | 视觉系统 (color tokens + typography scale + custom Path assets in `Resources/Assets.xcassets`) + App icon 设计稿 (Figma) + Figma 1 个 mock 给杨总看 | Figma mock + asset 清单 + 真机 build 编译通过 |
| **D2** Tue | S1 Setup 重做 + S5 About 重做 + clean debug 残留 (`motion=...` 那行 + `emergencyHold` binding) | 真机录屏 Setup flow 流畅 |
| **D3** Wed | S2 Ringing "Sunrise ring" 重做 + 微 haptic progressive (M5-M8) | 真机录屏 walk 50 步看到 fill 进 + burst |
| **D4** Thu | S3 Onboarding 3 步 + Tab bar 自定义 + 录 App Store screenshot 6.7"/6.1"/5.5" | 截图拍完 + onboarding 录屏 |
| **D5** Fri | **GLM session 跨模型 review**（防 AI 自审幻觉 · CLAUDE.md bar #3）+ 真机 walk-through 全流程 + privacy policy 校 + App Store metadata 写 + `xcrun altool --upload` 提交 | 提交成功 + 截图给杨总 |

**Review bar**（每 D 收尾 · 不靠 agent 自己看图）：
- 真机录屏 3 分钟一镜到底
- D2/D3 走 GLM session 反 review（指定 model = GLM，跨模型对抗幻觉）
- 截图真机拍（不靠 preview）

---

## 7 · 路上可能踩的坑（前置清单）

1. **App Store review reject** —— App icon 不能用 SF Symbol；必须自绘 PNG 多尺寸。Figma 出图 + 用 `Icon Composer` (Xcode 26) 导 .icon
2. **Info.plist NSMotionUsageDescription 文案太硬** —— 改写更温柔 "Walk Up 用你早晨的几步关掉闹钟，不会保留任何记录。"
3. **iOS 26 `.meshGradient` 是新 API**，旧 simulator 不支持 —— 真实机 iOS 26.6 才能完整跑；提交审核 iOS deployment target 调到 17 仍可
4. **`xcrun altool` deprecation** —— Xcode 26 走 `xcrun notarytool` + App Store Connect API；查最新 upload 流程
5. **Onboarding 文案英文** —— 准备 EN/中文两版，initial 推英文版（App Store 海外优先）
6. **跨模型 review 真做了吗** —— D5 设 reminder 必切 GLM session（CLAUDE.md 反幻觉硬尺）

---

## 8 · 需要杨总拍板 · **3 条 · 不阻塞 spec 落地**

1. **App icon 拍板** —— 出日 + 脚印叠加 / 单纯日出 / 极简文字 "U" + sunrise 渐变 三选一（我推 **日出 + 脚印**）：哪个？
2. **英文文案语气** —— 推 "Walk to wake up." tagline + "Wake up by walking." onboarding 头一句；还是更幽默走 alarm app 行话 (e.g. "Defeat the alarm")
3. **Onboarding 3 步数据采集** —— 是否埋点 (Onboarding 完成率 / step where drop)？默认 **不埋点** (Privacy first)

---

## 9 · Reference

### 9.1 Dribbble 268 shot 调研精华（2026-07-17 · web-fetcher 抓 6 个公开 tag search）

**6 个 tag 命中**：
| Tag | Hits | 关键参考 |
|---|---|---|
| alarm-clock-app | 48 | Fireart-d iOS Alarm · uxcratelab AI Alarm · Glass alarm clock |
| sleep-app | 43 | strangehelix asklepios/freud · Piqo Studio Sleep · Sleep Cycle 类不取 |
| wake-up-app | 41 | karina_bondarenko Social Alarm · orenjistudio Smart Sleep |
| morning-app | 46 | **karina_bondarenko Alarmi（最高密度）** · musemind AI Task |
| step-counter | 42 | **DD_UIUX Fitness Tracker UI Kit** · thien91dn Dynamic Island · Asish Sunny 动效 |
| wellness-app-ios | 48 | **asol_design / Anna Pastel UI（全 lavender 系）** · Tubik 微交互 |

**5 条对位启示**（agent §5）：
1. **配色二元** — 起床/步数走 warm pastel（#faefd1 / #f4b69c / #fad3d1）；睡眠走 deep navy/midnight
2. **ring dial + sunrise gradient + mission card** = 2024-2026 起床仪式感三件套（我们对）
3. **社交 + Gamification** 差异化空缺（Alarmi/Social 派）→ V2 备选，本期不动产品
4. **Widget / Dynamic Island** 是 iOS 化必做 → **推迟 D6+ post-launch**，不出现在 5 天 sprint
5. **App Store Screenshots 单独设计**（Orix Creative / The Screenshot First Company）→ D5 实施

**关键 designer follow 名单**：
- karina_bondarenko · uxcratelab · asol_design (Anna) · strangehelix · DD_UIUX · Fireart-d · Tubik · phenomonstudio · ramotion · beTomorrow · piqostudio · orixcreative · Pralay Bera (REM Smart Alarm)

### 9.2 Pinterest 抓取状态

- ❌ Pinterest 未通（HTML 公开搜索页是 JS-hydrate，pin 列表走 GraphQL + 懒加载，未登录 403）
- 📌 需要登录态：可走 `~/.local/share/uv/tools/.../webbridge` Chrome 复用（memory `webbridge-chrome-login-reuse.md` 验证过 minimax）—— D1 准备 Figma 时顺手装 B 登录

### 9.3 行业 iOS 标杆对位（不开）

- **Sleep Cycle** — dashboard chart 堆叠（明确不走）
- **Pillow** — 拟物 + chart（明确不走）
- **Alarmy** — 任务解锁（明确不走）
- **Dawn / Rise / CARROT Alarm** — 视觉对位 sample（不 clone，参考配色 / motion / 文案）

### 9.4 iOS 26 API（**能不用第三方库就能做出质感的关键**）
- `.meshGradient` (iOS 18+) — 多点 mesh gradient，sunrise 的柔和色块过渡
- `.symbolEffect(.pulse/.bounce/.variableColor)` — SF Symbol 的原生微动效
- `.contentTransition(.numericText())` — 数字翻牌
- `.sensoryFeedback` — 系统级 haptic
- `TimelineView(.animation)` — 连续呼吸动画

### 9.5 Apple WWDC26 Liquid Glass — 参考但不抄

- iOS 26 的 Liquid Glass 是 Apple 自家 linear/conic gradient + ultraThinMaterial 的延伸
- 我们做得更 editorial（手绘 + 大字 + 暖色）+ 不引第三方 ─ 比 Liquid Glass 更"独立 app"调性

---

## 10 · TODO（在杨总回 3 条前我能并行做的）

- [ ] Clean debug 残留（`motion=notDetermined (raw 0)` 那行 + `emergencyHold` binding 没用上的 dead state）
- [ ] 准备 Figma mock S1 + S2（先文字 wireframe，D1 给图）
- [ ] web-fetcher agent 抓 Dribbble / Pinterest 灵感 → enrich §9
- [ ] 启动 cron：D5 周五 09:00 reminder 切 GLM session cross-review（防飘）
